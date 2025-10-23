# kipu-bankV2.3
KipuBank version 2.3

Mejoras Realizadas:
Se definio el Contrato como Ownable y ERC20 importando contratos de OpenZeppelin:

  https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v5.0.2/contracts/access/Ownable.sol
    Ownable.sol: Control de acceso
  https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v5.0.2/contracts/token/ERC20/ERC20.sol
    ERC20.sol: Tokens ERC20
Se consulta otro contrato Oráculo chainlink para obtener el valor de USDC   
  @chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol
      AggregatorV3Interface.sol: Oráculo 
    
Se definieron mas eventos
Se definieron mas errores

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
 1- Desde Remix se despielga el contrato pasando valores de Limite de depositos y Limite de retiro x transaccion
 2- Desde una cta se puede depositar ether
 3- Desde una cta podemos "comprarTKB" con el etehr que tenemos depositado
 3- desde una cta podemos depositar ETH y al mismo tiempo comprar TKB si los saldo nos lo permiten
 4- Podemos obtener saldos de ETH y TKB, solo el contrato.
 5- Podemos retirar ETH de la boveda, trasnfiriendose el ETH a la cta que realiza el retiro.
 6- Podemos retirar TKB de la boveda, trasnfiriendose los TKB a la cta que realiza el retiro.
 
 
  
Trade-Offs.
  Se utilizo una structura cuando se podría habrer utilizado un mappingg anidado
