// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/**
 * @dev IERC20 is templete/interface for ERC20 token
 */
interface IERC20 {

    //Functions
    //opt-functions
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);

    //main-functions
    function totalSupply() external view returns (uint256); 
    function balanceOf(address _owner) external view returns (uint256);   
    function transfer(address _to, uint256 _value) external returns (bool);   
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool);  
    function approve(address _spender, uint256 _value) external returns (bool);  
    function allowance(address _owner, address _spender) external view returns (uint256);  

    //Events
    event Transfer(
      address indexed _from,
      address indexed _to,
      uint256 _value
    );  
    event Approval(
      address indexed _owner,
      address indexed _spender,
      uint256 _value
    );

}


error InsufficientFunds(uint256 balance, uint256 value);
error NeedApproval(uint256 approvedAmount, uint256 value);
error AllAtomsMined();
error NullAddress();

/**
 * @title Atom ERC20 token
 * @author Suresh Bennabatthula
 * @notice 
 * This contract provides atoms, these are ERC20 tokens
 * Each atom consists of '1000' electrons
 * electron is small unit of atom
 */

contract Atom is IERC20 {

    string private _name;
    string private _symbol;
    uint8 private _decimal;
    uint private _totalSupply;

    uint private _AtomPrice;
    uint private _ElectronPrice;

    /**
     * @dev balances map maps balance to its address,
     * balance will be in electrons, each atom will have 1000 electorns -- decimal 3
     * @dev allowed-map will have how much amount is allowed by a 
     * 3rd party to send atoms to another account on behalf of a user 
     * @dev totalsupply and minedAtoms will also be in electrons
     */

    /**
     * conversion between atoms and electrons
     * amountInAtoms = amountInElectrons / pow(10, decimals); 
     */

    mapping (address => uint) balances;
    mapping (address => mapping (address => uint)) allowed;
    uint private minedElectrons;

    constructor(uint _atomPrice) {
        _symbol = "AM";
        _name = "Atom";
        _decimal = 3;                   //1 atom = 1000 electrons
        _totalSupply = 10000 * 1000;    /**@dev 10,000 * 1,000 === atoms * 1000 = electrons | totalSupply = 10,000,000 electrons*/
        minedElectrons = 0;

        _AtomPrice = _atomPrice;
        _ElectronPrice = _atomPrice / (10 ** 3) ;
    }


    //opt-functions
    function name() external view override returns (string memory) {
        return _name;
    }
    function symbol() external view override returns (string memory) {
        return _symbol;
    }
    function decimals() external view override returns (uint8) {
        return _decimal;
    }

    
    /**
     * @dev totalSupply, balance are in electrons
     */
    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }
    function balanceOf(address _owner) external view override returns (uint256) {
        return balances[_owner];
    } 

    function MinedElectrons() external view returns(uint) {
        return minedElectrons;
    }
    function electronPrice() public view returns(uint) {
        return _ElectronPrice;
    }
    function atomPrice() public view returns(uint) {
        return _AtomPrice;
    }


    //main-functions
    /**
     * @dev users can send electrons to others using transfer function
     * _value needs to be send in electrons
     */

    function transfer(address _to, uint256 _value) external override returns (bool) {
        if(_value > balances[msg.sender]) revert InsufficientFunds(balances[msg.sender], _value);
        if(_to == address(0)) revert NullAddress();

        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    /**
     * allowed 3rd party will able to call this function and
     * do transactions behalf of users
     * @dev _value needs to be in electrons
     */

    function transferFrom(address _from, address _to, uint256 _value) external override returns (bool) {
        if(_value > balances[_from]) revert InsufficientFunds(balances[_from], _value);
        if(_value > allowed[_from][msg.sender]) revert NeedApproval(allowed[_from][msg.sender], _value);
        if(_to == address(0)) revert NullAddress();

        balances[_from] -= _value;
        balances[_to] += _value;
        allowed[_from][msg.sender] -= _value;

        emit Transfer(_from, _to, _value);
        return true;
    }

    /**
     * user can call this function with 3rd party adress, value
     * 3rd party will get allowed to user user electrons for (value) electrons
     * @dev value in electrons
     */

    function approve(address _spender, uint256 _value) external override returns (bool) {
        require(_spender != address(0));

        allowed[msg.sender][_spender] += _value;
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    /**
     * this function gives how many electrons are allowed to a 3rd party from a user
     */

    function allowance(address _owner, address _spender) external view override returns (uint256) {
        return allowed[_owner][_spender];
    }


    //extension functions
    function mintAtoms() public payable returns(bool) {

        uint _electronsToMine = msg.value / _ElectronPrice;
        if(minedElectrons + _electronsToMine > _totalSupply) revert AllAtomsMined();

        balances[msg.sender] += _electronsToMine;
        minedElectrons += _electronsToMine;

        emit Transfer(address(this), msg.sender, _electronsToMine);
        return true;
    }

    function burnElectrons(uint _value) public returns(bool) {
        if(_value > balances[msg.sender]) revert InsufficientFunds(balances[msg.sender], _value);

        minedElectrons -= _value;
        balances[msg.sender] -= _value;

        uint amount = _value * _ElectronPrice;
        (bool success, ) = (msg.sender).call{value: amount}("");
        return success;
    }

}