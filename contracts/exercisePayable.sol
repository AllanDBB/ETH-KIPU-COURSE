// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract exercisePayable {

    uint256 fee; // Fee en puntos básicos (1% = 100)
    address owner;
    uint256 treasury;

    // Constructor
    constructor(uint256 _fee) {
        fee = _fee;
        owner = msg.sender;
        treasury = 0;
    }

    // Estructura de usuario
    struct User {
        string firstName;
        string lastName;
        uint256 amount; // Saldo en ETH
        bool state;
    }

    // Eventos
    event UserRegistered(address indexed userAddress, string firstName, string lastName);
    event Deposit(address indexed userAddress, uint256 amount);
    event Withdraw(address indexed userAddress, uint256 amount);
    event WithdrawTreasury(address indexed owner, uint256 amount);

    // Mapping dirección -> usuario
    mapping(address => User) public users;

    // Modificadores
    modifier onlyRegistered() {
        require(bytes(users[msg.sender].firstName).length > 0, "User not registered");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "You aren't the owner of the contract");
        _;
    }

    // Registro de un usuario
    function register(string calldata _firstName, string calldata _lastName) external {
        require(bytes(users[msg.sender].firstName).length == 0, "User already registered");

        users[msg.sender] = User({
            firstName: _firstName,
            lastName: _lastName,
            amount: 0,
            state: true
        });

        emit UserRegistered(msg.sender, _firstName, _lastName);
    }

    // Depósito de fondos (en ETH)
    function deposit() external payable onlyRegistered {
        require(msg.value > 0, "Deposit amount must be greater than zero");
        users[msg.sender].amount += msg.value;

        emit Deposit(msg.sender, msg.value);
    }

    // Obtener el saldo del usuario
    function getBalance() external view onlyRegistered returns (uint256) {
        return users[msg.sender].amount;
    }

    // Retiro de fondos (en ETH)
    function withdraw(uint256 _amount) external onlyRegistered {
        require(users[msg.sender].amount >= _amount, "Not enough amount.");

        uint256 feeToPay = (_amount * fee) / 10000;
        uint256 amountAfterFee = _amount - feeToPay;

        // Actualizar el saldo del usuario
        users[msg.sender].amount -= _amount;

        // Actualizar la tesorería
        treasury += feeToPay;

        // Transferir el ETH al usuario
        payable(msg.sender).transfer(amountAfterFee);

        emit Withdraw(msg.sender, amountAfterFee);
    }

    // Retiro de fondos de la tesorería
    function withdrawTreasury(uint256 _amount) external onlyOwner {
        require(treasury >= _amount, "Not enough funds in the treasury.");

        treasury -= _amount;
        payable(owner).transfer(_amount);

        emit WithdrawTreasury(owner, _amount);
    }

    // Obtener balance de la tesorería

    function getTreasury() external view onlyOwner returns(uint256) {
        return treasury;
    }
}
