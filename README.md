# DeFi Staking System

## Contratos deployados en Sepolia Testnet

| Contrato | Dirección |
|----------|-----------|
| RewardToken (BEE) | `0x51296AcFdB85966EfE624A4562B1761014dB419b` |
| StakingRewards | `0xC44474aC35d6882e246bEB0A63228911DB2bB208` |

## Links
- **RewardToken en Etherscan:** https://sepolia.etherscan.io/address/0x51296AcFdB85966EfE624A4562B1761014dB419b
- **StakingRewards en Etherscan:** https://sepolia.etherscan.io/address/0xC44474aC35d6882e246bEB0A63228911DB2bB208

---

## 4.2 Tabla de evidencia del deploy

| Contrato | Dirección en Sepolia | ¿Verificado ? | Tx hash deploy |
| :--- | :--- | :--- | :--- |
| **RewardToken.sol** | `0x51296AcFdB85966EfE624A4562B1761014dB419b` | Sí (post verificación) | `0xca409edcd98d88307d8253a0c6eaa0cf1381afa3b938f8dc9245e86e1454f836` |
| **StakingRewards.sol** | `0xC44474aC35d6882e246bEB0A63228911DB2bB208` | Sí (post verificación) | `0xc297bb0b9d12548cef06607882172f56457e0d1fa8ca8e4942917c30b8058774` |
| **Tx interacción cross contract** | `getReward() -> mintReward()` | — | `0x36e52ab7a8dfbbc446c3bec4808f47d96a5101e3a27f66cded455edffa3467d1` |

###  Historial de Transacciones de Soporte (Auditoría de Calidad)
* **Configuración Inicial (`Set Rewards Duration`):** `0x2fd22c3b5d5bdde5338c0fefcbbd9d8212e02720af42a9fb64a1d889b82b4c53`
* **Prueba de Robustez (Manejo de Errores - `Out of Gas Reentrancy`):** `0xbdc1733b4a27324a29061814f484014b76c625fee55243913aba769f72315119`
