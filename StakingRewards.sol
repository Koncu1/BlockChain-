// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;


import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


/// @title StakingRewards — Depositar tokens y ganar recompensas
/// @notice Implementación del patrón Synthetix de distribución de rewards.
///         Llama a RewardToken.mintReward() para emitir recompensas.
contract StakingRewards is ReentrancyGuard, Ownable {


    // ── Tokens ────────────────────────────────────────────────────
    /// @notice Token que los usuarios depositan para hacer staking.
    IERC20 public immutable stakingToken;


    /// @notice Token de recompensa — se mintea al reclamar.
    IRewardToken public immutable rewardsToken;


    // ── Parámetros de la campaña ──────────────────────────────────
    /// @notice Duración de la campaña de rewards en segundos.
    uint256 public duration;


    /// @notice Timestamp en que finaliza la campaña activa.
    uint256 public finishAt;


    /// @notice Rewards por segundo calculado en notifyRewardAmount().
    uint256 public rewardRate;


    // ── Acumuladores ─────────────────────────────────────────────
    uint256 public rewardPerTokenStored;
    uint256 public lastUpdateTime;
    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;


    // ── Estado del staking ────────────────────────────────────────
    /// @notice Supply total de tokens en staking.
    uint256 public totalSupply;


    /// @notice Balance de staking de cada usuario.
    mapping(address => uint256) public balanceOf;


    // ── Eventos ───────────────────────────────────────────────────
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardClaimed(address indexed user, uint256 amount);
    event RewardNotified(uint256 amount, uint256 duration);


    // ── Errores custom ────────────────────────────────────────────
    error AmountZero();
    error InsufficientBalance(uint256 available, uint256 requested);


    constructor(address _stakingToken, address _rewardsToken)
        Ownable(msg.sender)
    {
        stakingToken = IERC20(_stakingToken);
        rewardsToken = IRewardToken(_rewardsToken);
    }


    // ── Modifier ─────────────────────────────────────────────────
    modifier updateReward(address _account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (_account != address(0)) {
            rewards[_account] = earned(_account);
            userRewardPerTokenPaid[_account] = rewardPerTokenStored;
        }
        _;
    }


    // ── Vistas ────────────────────────────────────────────────────
    /// @notice Último timestamp en que aplican rewards (min entre ahora y finishAt).
    /// @return Timestamp aplicable.
    function lastTimeRewardApplicable() public view returns (uint256) {
        return block.timestamp < finishAt ? block.timestamp : finishAt;
    }


    /// @notice Rewards acumulados por token depositado hasta ahora.
    /// @return Valor del acumulador en wei.
    function rewardPerToken() public view returns (uint256) {
        if (totalSupply == 0) return rewardPerTokenStored;
        return rewardPerTokenStored +
            (rewardRate * (lastTimeRewardApplicable() - lastUpdateTime) * 1e18)
            / totalSupply;
    }


    /// @notice Rewards ganados y no reclamados de un usuario.
    /// @param _account Dirección del usuario.
    /// @return Cantidad de rewards en wei.
    function earned(address _account) public view returns (uint256) {
        return
            (balanceOf[_account] * (rewardPerToken() - userRewardPerTokenPaid[_account]))
            / 1e18 + rewards[_account];
    }


    // ── Escritura ─────────────────────────────────────────────────
    /// @notice Depositar tokens en el pool de staking.
    /// @dev Requiere approve() previo en el stakingToken.
    /// @param _amount Cantidad de tokens a depositar (en wei).
    function stake(uint256 _amount) external nonReentrant updateReward(msg.sender) {
        if (_amount == 0) revert AmountZero();
        balanceOf[msg.sender] += _amount;
        totalSupply += _amount;
        stakingToken.transferFrom(msg.sender, address(this), _amount);
        emit Staked(msg.sender, _amount);
    }


    /// @notice Retirar tokens del pool de staking.
    /// @param _amount Cantidad a retirar (en wei).
    function withdraw(uint256 _amount) external nonReentrant updateReward(msg.sender) {
        if (_amount == 0) revert AmountZero();
        if (balanceOf[msg.sender] < _amount)
            revert InsufficientBalance(balanceOf[msg.sender], _amount);
        // CEI: primero effects, luego interaction
        balanceOf[msg.sender] -= _amount;
        totalSupply -= _amount;
        stakingToken.transfer(msg.sender, _amount);
        emit Withdrawn(msg.sender, _amount);
    }


    /// @notice Reclamar las recompensas acumuladas.
    /// @dev Llama a RewardToken.mintReward() — interacción cross-contract.
    function getReward() external nonReentrant updateReward(msg.sender) {
        uint256 reward = rewards[msg.sender];
        if (reward > 0) {
            // CEI: effect antes de interaction
            rewards[msg.sender] = 0;
            rewardsToken.mintReward(msg.sender, reward);
            emit RewardClaimed(msg.sender, reward);
        }
    }


    /// @notice Configurar una nueva campaña de rewards. Solo owner.
    /// @param _amount  Cantidad total de rewards en wei.
    function notifyRewardAmount(uint256 _amount)
        external onlyOwner updateReward(address(0))
    {
        if (block.timestamp >= finishAt) {
            rewardRate = _amount / duration;
        } else {
            uint256 remaining = finishAt - block.timestamp;
            uint256 leftover = remaining * rewardRate;
            rewardRate = (_amount + leftover) / duration;
        }
        lastUpdateTime = block.timestamp;
        finishAt = block.timestamp + duration;
        emit RewardNotified(_amount, duration);
    }


    /// @notice Configurar la duración de la campaña en segundos. Solo owner.
    /// @param _duration Duración en segundos (ej. 7 días = 604800).
    function setRewardsDuration(uint256 _duration) external onlyOwner {
        require(block.timestamp > finishAt, 'Campana activa');
        duration = _duration;
    }
}


/// @dev Interfaz mínima de RewardToken que necesita StakingRewards.
interface IRewardToken {
    function mintReward(address to, uint256 amount) external;
}
