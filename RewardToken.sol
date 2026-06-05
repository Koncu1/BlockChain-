// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;


import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


/// @title RewardToken — Token ERC-20 del sistema DeFi
/// @notice Token fungible minteable solo por el contrato StakingRewards.
///         Hereda ERC20 y Ownable de OpenZeppelin.
contract RewardToken is ERC20, Ownable {


    /// @notice Dirección del contrato de staking autorizado a mintear.
    address public stakingContract;


    /// @notice Emitido cuando se autoriza un nuevo staking contract.
    event StakingContractSet(address indexed newContract);


    /// @dev Error custom: dirección zero no permitida.
    error ZeroAddress();


    /// @dev Error custom: solo el staking contract puede mintear.
    error NotStakingContract();


    /// @notice Deployar el token con supply inicial para el owner.
    /// @param nombre     Nombre del token (ej. 'KoncuratToken').
    /// @param simbolo    Símbolo del token (ej. 'KTK').
    /// @param supplyInicial  Supply enviado al owner en el deploy.
    constructor(
        string memory nombre,
        string memory simbolo,
        uint256 supplyInicial
    ) ERC20(nombre, simbolo) Ownable(msg.sender) {
        _mint(msg.sender, supplyInicial * 10 ** decimals());
    }


    /// @notice Autorizar una dirección como staking contract.
    /// @dev Solo el owner puede llamar esta función.
    /// @param _staking Dirección del contrato StakingRewards.
    function setStakingContract(address _staking) external onlyOwner {
        if (_staking == address(0)) revert ZeroAddress();
        stakingContract = _staking;
        emit StakingContractSet(_staking);
    }


    /// @notice Mintear tokens de recompensa. Solo callable por stakingContract.
    /// @param to     Destinatario de los tokens minteados.
    /// @param amount Cantidad en wei (18 decimales).
    function mintReward(address to, uint256 amount) external {
        if (msg.sender != stakingContract) revert NotStakingContract();
        _mint(to, amount);
    }
}
