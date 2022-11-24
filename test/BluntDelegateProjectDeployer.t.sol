// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import './helper/BluntSetup.sol';
import 'contracts/BluntDelegateProjectDeployer.sol';
import 'contracts/BluntDelegateDeployer.sol';
import 'contracts/BluntDelegateCloner.sol';
import 'contracts/interfaces/IBluntDelegateDeployer.sol';
import 'contracts/interfaces/IBluntDelegateCloner.sol';

contract BluntDelegateProjectDeployerTest is BluntSetup {
  BluntDelegateProjectDeployer public bluntDeployer;
  IBluntDelegateDeployer public delegateDeployer;
  IBluntDelegateCloner public delegateCloner;

  function setUp() public virtual override {
    BluntSetup.setUp();

    delegateDeployer = new BluntDelegateDeployer();
    delegateCloner = new BluntDelegateCloner();

    bluntDeployer = new BluntDelegateProjectDeployer(
      delegateDeployer,
      delegateCloner,
      _jbController,
      _jbOperatorStore,
      address(uint160(uint256(keccak256('eth')))),
      address(uint160(uint256(keccak256('usdc'))))
    );
  }

  function testLaunchProject() public {
    (
      DeployBluntDelegateData memory deployBluntDelegateData,
      JBLaunchProjectData memory launchProjectData
    ) = _formatDeployData();

    uint256 projectId = bluntDeployer.launchProjectFor(
      deployBluntDelegateData,
      launchProjectData,
      _clone
    );

    assertEq(projectId, 1);
  }

  function testDelegateAddressIsProjectOwner() public {
    (
      DeployBluntDelegateData memory deployBluntDelegateData,
      JBLaunchProjectData memory launchProjectData
    ) = _formatDeployData();

    uint256 projectId = bluntDeployer.launchProjectFor(
      deployBluntDelegateData,
      launchProjectData,
      _clone
    );
    address owner = _jbProjects.ownerOf(projectId);
    (, JBFundingCycleMetadata memory metadata) = _jbController.currentFundingCycleOf(projectId);

    assertEq(owner, metadata.dataSource);
  }

  function testMetadataOverwrite() public {
    (
      DeployBluntDelegateData memory deployBluntDelegateData,
      JBLaunchProjectData memory launchProjectData
    ) = _formatDeployData();

    // Set wrong metadata
    launchProjectData.metadata.dataSource = address(2);
    launchProjectData.metadata.useDataSourceForPay = false;
    launchProjectData.metadata.useDataSourceForRedeem = false;
    launchProjectData.metadata.redemptionRate = 2;
    launchProjectData.metadata.global.pauseTransfers = false;

    uint256 projectId = bluntDeployer.launchProjectFor(
      deployBluntDelegateData,
      launchProjectData,
      _clone
    );
    (, JBFundingCycleMetadata memory metadata) = _jbController.currentFundingCycleOf(projectId);

    assertFalse(metadata.dataSource == address(2));
    assertBoolEq(metadata.useDataSourceForPay, true);
    assertBoolEq(metadata.useDataSourceForRedeem, true);
    assertEq(metadata.redemptionRate, JBConstants.MAX_REDEMPTION_RATE);
    assertBoolEq(metadata.global.pauseTransfers, true);
  }

  ///////////////////////////////////////
  /////////////// REVERTS ///////////////
  ///////////////////////////////////////
  function testRevertInvalidWeight() public {
    (
      DeployBluntDelegateData memory deployBluntDelegateData,
      JBLaunchProjectData memory launchProjectData
    ) = _formatDeployData();

    launchProjectData.data.weight = 0;

    hevm.expectRevert(bytes4(keccak256('INVALID_TOKEN_ISSUANCE()')));
    bluntDeployer.launchProjectFor(deployBluntDelegateData, launchProjectData, _clone);

    launchProjectData.data.weight = 1e14;

    hevm.expectRevert(bytes4(keccak256('INVALID_TOKEN_ISSUANCE()')));
    bluntDeployer.launchProjectFor(deployBluntDelegateData, launchProjectData, _clone);
  }
}
