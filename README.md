# kipu-bankV2.3
KipuBank version 2
Una explicación a alto nivel de las mejoras realizadas y el motivo de ellas.
Mejoras Realizadas:
Se definio el Contrato como Ownable y ERC20 importando contratos de OpenZeppelin:

  https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v5.0.2/contracts/access/Ownable.sol
    Ownable.sol: Control de acceso
  https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v5.0.2/contracts/token/ERC20/ERC20.sol
    ERC20.sol: Tokens ERC20
Se consulta otro contrato Oráculo chainlink para obtener el valor de USDC   
  @chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol
      AggregatorV3Interface.sol: Oráculo 
    
Se creo una estructura de datos "Cuenta" para mantener un saldo de ether y un saldo de TKB
Se crearon las siguentes funciones:

  venderTKB
  comprarTKB
  depositarETH
  depositarETHyComprarTKB
  obtenerSaldos
  retirarTKB
  retirarETH

  convertirETHaUSD
  convertirETHaTKB
  convertirTKBaETH


Instrucciones de despliegue e interacción.
 Desde Remix se despielga el contrato pasando valores de Limite de depositos y Limite de retiro x transaccion
 
  
Trade-Offs.
  Se utilizo una structura cuando se podría habrer utilizado un mappingg anidado
