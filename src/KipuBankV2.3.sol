// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title KipuBank - Banco descentralizado simple
/// @author GOC 
/// @notice Cada usuario tiene su bóveda personal de ETH.

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v5.0.2/contracts/access/Ownable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v5.0.2/contracts/token/ERC20/ERC20.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";


contract KipuBank is Ownable, ERC20 {

    /*//////////////////////////////////////////////////////////////
                                ERRORES
    //////////////////////////////////////////////////////////////*/
    error KipuBank_DepositosLimiteReachazado();
    error KipuBank_DepositosReachazadoTKB0();
    error KipuBank_RetiroReachazadoTKB0();
    error KipuBank_CompraTKBRechazada();
    error KipuBank_VentaTKBRechazada();
    error KipuBank_LimiteRetirosExcedidos(uint256 requested, uint256 limit);
    error KipuBank_SaldoInsuficiente(uint256 requested, uint256 available);
    error KipuBank_SaldoInsuficientedelContarto(address contrato , uint256 cant);
    error KipuBank_FallaTransferencia();


    /*//////////////////////////////////////////////////////////////
                                EVENTOS
    //////////////////////////////////////////////////////////////*/
    event Depo(address indexed user, uint256 amount, uint256 tokens);
    event Reti(address indexed user, uint256 amount);
    event Log(string NombreFuncion, address sender, uint amount, bytes data);
    event Quema(address indexed user, uint256 amount, uint256 tokens);

    /*//////////////////////////////////////////////////////////////
                           VARIABLES DE ESTADO
    //////////////////////////////////////////////////////////////*/
    /// @notice bóveda personal de cada usuario

    struct Cuenta {
        uint256 saldoETH;
        uint256 saldoTKB;
    }

    mapping(address => Cuenta) private s_boveda;
    
    /// @notice límite global de depósitos
    //  bankCap
    uint256 public immutable i_LimiteDepositos;

    /// @notice límite de retiro por transacción
    uint256 public immutable i_LimiteRetirosXTransaccion;

    /// @notice total de depósitos acumulados
    uint256 public s_TotalDepositosETHAcumulados;

    uint256 private s_TotalDepositosRealizados;
    uint256 private s_TotalRetirosRealizados; 
   
     AggregatorV3Interface internal priceFeed;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(uint256 _LimiteDepositos, uint256 _LimiteRetirosXTransaccion) Ownable(msg.sender) ERC20("TokenKipu", "TKB") {

        //1 ETH = 1000000000000000000 wei

        i_LimiteDepositos = _LimiteDepositos * 1000000000000000000;
        i_LimiteRetirosXTransaccion = _LimiteRetirosXTransaccion * 1000000000000000000;

        // Dirección del contrato Chainlink ETH/USD en Sepolia Testnet
        // Fuente oficial: https://docs.chain.link/data-feeds/price-feeds/addresses
        priceFeed = AggregatorV3Interface(
            0x694AA1769357215DE4FAC081bf1f309aDC325306
        );  

    } 

    /*//////////////////////////////////////////////////////////////
                               FUNCIONES
    //////////////////////////////////////////////////////////////*/
    
    fallback() external payable { 
        emit Log("fallback",msg.sender,msg.value,msg.data);
        revert();
    }
    receive() external payable {
        emit Log("receive",msg.sender,msg.value,"");
        revert();
    }

    //@notice Permite depositar ETH para comprar TKB en tu bóveda
    function depositarETH() external payable {     
       
        if (s_TotalDepositosETHAcumulados + msg.value > i_LimiteDepositos) {
            revert KipuBank_DepositosLimiteReachazado();
        }

        s_boveda[msg.sender].saldoETH += msg.value;

        s_TotalDepositosETHAcumulados += msg.value;
        s_TotalDepositosRealizados++;
        emit Depo(msg.sender, msg.value,0);
    }

    //@notice Permite depositar ETH para comprar TKB realiza el cambio directamente
    function depositarETHyComprarTKB() external payable {

        uint256 u_tokensTKBGMinados;
       
       
        if (s_TotalDepositosETHAcumulados + msg.value > i_LimiteDepositos) {
            revert KipuBank_DepositosLimiteReachazado();
        }

        u_tokensTKBGMinados = convertirETHaTKB(msg.value);
        if (u_tokensTKBGMinados == 0) {
            revert KipuBank_DepositosReachazadoTKB0();
        }        
       
       _mint(address(this), u_tokensTKBGMinados * 10 ** 18);
        
        emit Depo(msg.sender, msg.value,u_tokensTKBGMinados);

        s_boveda[msg.sender].saldoTKB += u_tokensTKBGMinados;

        //s_TotalDepositosETHAcumulados += msg.value;
        s_TotalDepositosRealizados++;
    }
    //@notice compra TKB con una cantidad de eth suma lo que se envia mas lo que tiene depositado
    //@param _cantidadETH es la cant de ether que deseo enviar para comprar o cambiar x tokens
    function comprarTKB(uint256 _cantidadETH) external payable {

        uint256  u_tokensTKBGMinados;
     
   
        if (s_TotalDepositosETHAcumulados + msg.value > i_LimiteDepositos) {
            revert KipuBank_DepositosLimiteReachazado();
        }
        s_boveda[msg.sender].saldoETH += msg.value;
    
        
        if (s_boveda[msg.sender].saldoETH < _cantidadETH){
           revert KipuBank_CompraTKBRechazada();         
        }

        u_tokensTKBGMinados = convertirETHaTKB(_cantidadETH);
        if (u_tokensTKBGMinados == 0) {
            revert KipuBank_DepositosReachazadoTKB0();
        }        
       
       _mint(address(this), u_tokensTKBGMinados * 10 ** 18);
         
        s_boveda[msg.sender].saldoETH -= _cantidadETH;
        s_boveda[msg.sender].saldoTKB += u_tokensTKBGMinados;

        //s_TotalDepositosETHAcumulados += msg.value;
        //s_TotalDepositosRealizados++;

        emit Depo(msg.sender, msg.value,u_tokensTKBGMinados);

    }
    //@notice vender TKB pasa al valor del eth una cantidad de tokens y luego los quema 
    //@param _cantidadETH es la cant de ether que deseo enviar para comprar o cambiar x tokens
    function venderTKB(uint256 _cantidadTKB) external payable {

        uint256  u_ETH;

        if(s_boveda[msg.sender].saldoTKB < _cantidadTKB){
            revert KipuBank_VentaTKBRechazada();
        }
        
        u_ETH = convertirTKBaETH(_cantidadTKB);


       _burn(address(this), _cantidadTKB); 
         
        s_boveda[msg.sender].saldoETH +=  u_ETH;
        s_boveda[msg.sender].saldoTKB -= _cantidadTKB;

        
        emit Quema(msg.sender, msg.value,_cantidadTKB);
    }


/// @notice Devuelve los saldos en ETH y TKB  de una cuenta en la boveda
    function obtenerSaldos(address _usuario) external view onlyOwner returns (uint256 eth, uint256 tokens) {
        return (s_boveda[_usuario].saldoETH, s_boveda[_usuario].saldoTKB);
    }
    /// @notice Devuelve la cantidad rde retiros realizados x el SC
    function obtenerCantidadRetiros() external view returns (uint256) {
        return s_TotalRetirosRealizados;
    }
 
     /// @notice Devuelve la cantidad rde depositos realizados x el SC
    function obtenerCantidadDepositos() external view returns (uint256) {
        return s_TotalDepositosRealizados;
    }

    /// @notice calcula la cantidad de Operaciones
    function calculaCantidadOperaciones() private view returns (uint256){
        return s_TotalDepositosRealizados + s_TotalRetirosRealizados;
    }

    /// @notice Devuelve la cantidad Operaciones realizados x el SC
    function obtenerCantidadOperacionesRealizadas() public view returns (uint256){
        return calculaCantidadOperaciones();
    }    

    /// @notice Retira TKB de la boveda y lo transfiere a la cuenta que invoca
    /// @param _cantidad cantidad de TKB a retirar de la boveda de la cuenta 
    function retirarTKB(uint256 _cantidad) external payable{
             
        if (_cantidad > s_boveda[msg.sender].saldoTKB) {
            revert KipuBank_SaldoInsuficiente(_cantidad, s_boveda[msg.sender].saldoTKB);
        }

            if(this.balanceOf(address(this)) >= _cantidad){
                this.transfer(msg.sender, _cantidad);
            }else revert KipuBank_SaldoInsuficientedelContarto(address(this), _cantidad);
                

        s_boveda[msg.sender].saldoTKB -= _cantidad;
        s_TotalRetirosRealizados++;
 
        emit Reti(msg.sender, _cantidad);
    }
    /// @notice Retira ETH de la boveda y lo transfiere a la cuenta que invoca
    /// @param _cantidad cantidad de ETH a retirar de la boveda de la cuenta 
    function retirarETH(uint256 _cantidad) external payable{
        
              
        if (_cantidad > i_LimiteRetirosXTransaccion) {
            revert KipuBank_LimiteRetirosExcedidos(_cantidad, i_LimiteRetirosXTransaccion);
        }
        if (_cantidad > s_boveda[msg.sender].saldoETH) {
            revert KipuBank_SaldoInsuficiente(_cantidad, s_boveda[msg.sender].saldoETH);
        }

        if(address(this).balance >= _cantidad){
            (bool ok, ) = msg.sender.call{value: _cantidad}("");
            if (!ok) {
                revert KipuBank_FallaTransferencia();
            }
        }
        
        s_boveda[msg.sender].saldoETH -= _cantidad;
        
    
        s_TotalDepositosETHAcumulados -= _cantidad;
        s_TotalRetirosRealizados++;
  
        emit Reti(msg.sender, _cantidad);
    }


    function enviarETH(address payable destinatario, uint256 cantidad) external {
            require(address(this).balance >= cantidad, "Fondos insuficientes");

            (bool exito, ) = destinatario.call{value: cantidad}("");
            require(exito, "Fallo al enviar ETH");
    }

    //valores del ETHER chainlink
    //Obtiene el último precio de ETH/USD
    function getPrecioETH() public view returns (int) {
    (
            , 
            int precio, 
            , 
            , 
            
        ) = priceFeed.latestRoundData();

        // El precio tiene 8 decimales, por ejemplo: 340000000000 = $3400.00000000
        return precio;
    }

    //Convierte un monto en wei (ETH * 1e18) a USD (sin decimales)
    function convertirETHaUSD(uint256 amountInWei) public view returns (uint256) {
        int i_precio = getPrecioETH(); 
        // Precio en USD con 8 decimales
        // (precio * ETH) / (1e8 * 1e18) = USD
        //uint256 usd = (uint256(precio) * amountInWei) / 1e26;
        uint256 valorUSD = (uint256(i_precio) * amountInWei) / (1e8 * 1e18);
        return valorUSD;               
    }
    function convertirETHaUSDC(uint256 cantidadWei) public view returns (uint256) {
        (, int256 price,,,) = priceFeed.latestRoundData(); // ETH/USD con 8 decimales
        // Fórmula: (wei * price * 1e6) / (1e18 * 1e8)
        uint256 cantidadUSDC = (cantidadWei * uint256(price) * 1e6) / (1e18 * 1e8);
        return cantidadUSDC;
    }
    //Convierte un monto en Wei a TKB
    function convertirETHaTKB(uint256 amountInWei) public view returns (uint256) {
        uint256 u_precioETHenUSD = convertirETHaUSD(amountInWei); // Precio en USD con 8 decimales
        /// (precio * ETH) / (1e8 * 1e18) = USD
        uint256 TKB = u_precioETHenUSD;
        return TKB;
    }
    //Convierte una cantidad TKB a Wei
    function convertirTKBaETH(uint256 _cantidadTKB) public view  returns (uint256) {
          int i_precio = getPrecioETH();
          uint256 u_ETH = _cantidadTKB * (uint256(i_precio));  
        return u_ETH;
    }
     
}
