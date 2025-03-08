// SPDX-License-Identifier: MIT
pragma solidity >=0.8.2 <0.9.0;

interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[ERC section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}



interface IERC721 is IERC165 {
    /// @dev This emits when ownership of any NFT changes by any mechanism.
    ///  This event emits when NFTs are created (`from` == 0) and destroyed
    ///  (`to` == 0). Exception: during contract creation, any number of NFTs
    ///  may be created and assigned without emitting Transfer. At the time of
    ///  any transfer, the approved address for that NFT (if any) is reset to none.
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);

    /// @dev This emits when the approved address for an NFT is changed or
    ///  reaffirmed. The zero address indicates there is no approved address.
    ///  When a Transfer event emits, this also indicates that the approved
    ///  address for that NFT (if any) is reset to none.
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);

    /// @dev This emits when an operator is enabled or disabled for an owner.
    ///  The operator can manage all NFTs of the owner.
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    /// @notice Count all NFTs assigned to an owner
    /// @dev NFTs assigned to the zero address are considered invalid, and this
    ///  function throws for queries about the zero address.
    /// @param _owner An address for whom to query the balance
    /// @return The number of NFTs owned by `_owner`, possibly zero
    function balanceOf(address _owner) external view returns (uint256);

    /// @notice Find the owner of an NFT
    /// @dev NFTs assigned to zero address are considered invalid, and queries
    ///  about them do throw.
    /// @param _tokenId The identifier for an NFT
    /// @return The address of the owner of the NFT
    function ownerOf(uint256 _tokenId) external view returns (address);

    /// @notice Transfers the ownership of an NFT from one address to another address
    /// @dev Throws unless `msg.sender` is the current owner, an authorized
    ///  operator, or the approved address for this NFT. Throws if `_from` is
    ///  not the current owner. Throws if `_to` is the zero address. Throws if
    ///  `_tokenId` is not a valid NFT. When transfer is complete, this function
    ///  checks if `_to` is a smart contract (code size > 0). If so, it calls
    ///  `onERC721Received` on `_to` and throws if the return value is not
    ///  `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    /// @param data Additional data with no specified format, sent in call to `_to`
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory data) external payable;

    /// @notice Transfers the ownership of an NFT from one address to another address
    /// @dev This works identically to the other function with an extra data parameter,
    ///  except this function just sets data to "".
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external payable;

    /// @notice Transfer ownership of an NFT -- THE CALLER IS RESPONSIBLE
    ///  TO CONFIRM THAT `_to` IS CAPABLE OF RECEIVING NFTS OR ELSE
    ///  THEY MAY BE PERMANENTLY LOST
    /// @dev Throws unless `msg.sender` is the current owner, an authorized
    ///  operator, or the approved address for this NFT. Throws if `_from` is
    ///  not the current owner. Throws if `_to` is the zero address. Throws if
    ///  `_tokenId` is not a valid NFT.
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    function transferFrom(address _from, address _to, uint256 _tokenId) external payable;

    /// @notice Change or reaffirm the approved address for an NFT
    /// @dev The zero address indicates there is no approved address.
    ///  Throws unless `msg.sender` is the current NFT owner, or an authorized
    ///  operator of the current owner.
    /// @param _approved The new approved NFT controller
    /// @param _tokenId The NFT to approve
    function approve(address _approved, uint256 _tokenId) external payable;

    /// @notice Enable or disable approval for a third party ("operator") to manage
    ///  all of `msg.sender`'s assets
    /// @dev Emits the ApprovalForAll event. The contract MUST allow
    ///  multiple operators per owner.
    /// @param _operator Address to add to the set of authorized operators
    /// @param _approved True if the operator is approved, false to revoke approval
    function setApprovalForAll(address _operator, bool _approved) external;

    /// @notice Get the approved address for a single NFT
    /// @dev Throws if `_tokenId` is not a valid NFT.
    /// @param _tokenId The NFT to find the approved address for
    /// @return The approved address for this NFT, or the zero address if there is none
    function getApproved(uint256 _tokenId) external view returns (address);

    /// @notice Query if an address is an authorized operator for another address
    /// @param _owner The address that owns the NFTs
    /// @param _operator The address that acts on behalf of the owner
    /// @return True if `_operator` is an approved operator for `_owner`, false otherwise
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}


interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be
     * reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}


abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}



contract Glasses42 is IERC721, ERC165 {
    string private _name;
    string private _symbol;
    address private _contract_owner;
    uint256 private _token_id_count;

    mapping(uint256 tokenId => address) private _owners;
    mapping(address owner => uint256) private _balances;
    mapping(uint256 tokenId => address) private _tokenApprovals;
    mapping(address owner => mapping(address operator => bool)) private _operatorApprovals;

    mapping(uint256 tokenId => string) private _tokenURIs;

    constructor(){
        _name = "GLASSES42";
        _symbol = "G42";
        _contract_owner = msg.sender;
        _token_id_count = 1337;
    }

    function tokenURI(uint256 _tokenId) external view returns (string memory){
        _requireOwned(_tokenId);

        string memory _tokenURI = _tokenURIs[_tokenId];
        if (bytes(_tokenURI).length > 0){
            return _tokenURI;
        }
        else {
            return "";
        }
        // string memory _base = _baseURI();

        // if (bytes(_base).length == 0){
        // }

    }

    modifier _onlyContractOwner {
        require (msg.sender == _contract_owner, "sender is not the owner of the contract");
        _;
    }

    function mint42(address _to, string calldata _tokenURI) public _onlyContractOwner {
        require(_to != address(0), "the reveiver address is not valid");
        _tokenURIs[_token_id_count] = _tokenURI;
        _owners[_token_id_count] = _to;
        _balances[_to] += 1;
        emit Transfer(_contract_owner, _to, _token_id_count);
        _token_id_count++;
    }

    // event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
    // event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);
    // event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            // interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }
    
    function _requireOwned(uint256 tokenId) private view returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "the token doesn't have an owner");
        return owner;
    }

    function balanceOf(address _owner) public view returns (uint256) {
        require(_owner != address(0), "invalid owner");
        return _balances[_owner];
    }

    function ownerOf(uint256 _tokenId) external view returns (address){
        return _requireOwned(_tokenId);
    }

    function name() public view virtual returns (string memory) {
        return _name;
    }

    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    function approve(address _approved, uint256 _tokenId) external payable {
        address owner = _requireOwned(_tokenId);
        require(owner == msg.sender || isApprovedForAll(owner, msg.sender), "sender is not allowed to control the token");

        _tokenApprovals[_tokenId] = _approved;
        emit Approval(owner, _approved, _tokenId);
    }

    function setApprovalForAll(address _operator, bool _approved) external {
        require(_operator != address(0), "invalid operator");
        _operatorApprovals[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    function getApproved(uint256 _tokenId) external view returns (address) {
        _requireOwned(_tokenId);
        return _tokenApprovals[_tokenId];
    }

    function isApprovedForAll(address _owner, address _operator) public view virtual returns (bool) {
        return _operatorApprovals[_owner][_operator];
    }


    function transferFrom(address _from, address _to, uint256 _tokenId) external payable {
        _transferFrom(_from, _to, _tokenId);
    }

    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes  memory data ) external payable{
        _transferFrom(_from, _to, _tokenId);
        _checkOnERC721Received(_from, _to, _tokenId, data);
    }

    function safeTransferFrom(address _from, address _to, uint256 _tokenId ) external payable{
        _transferFrom(_from, _to, _tokenId);
        _checkOnERC721Received(_from, _to, _tokenId, "");
    }

    function _transferFrom(address _from, address _to, uint256 _tokenId) private {
        require(_to != address(0), "Invalid reciever");
        address owner = _requireOwned(_tokenId);
        require(owner == _from, "Not the owner");
        // require(owner == msg.sender || _tokenApprovals[_tokenId] == msg.sender || isApprovedForAll(owner, msg.sender));
        require(owner == msg.sender || _isApproved(msg.sender, _tokenId) || isApprovedForAll(owner, msg.sender));
        _tokenApprovals[_tokenId] = address(0);
        _balances[_from] -= 1;
        _balances[_to] += 1;
        _owners[_tokenId] = _to;
        emit Transfer(_from, _to, _tokenId);
    }
    function _isApproved(address _addr, uint256 _tokenId) private view returns(bool) {
        return _tokenApprovals[_tokenId] == _addr;
    }

    function _checkOnERC721Received(address _from, address _to, uint256 _tokenId, bytes memory _data) private returns (bool){
        if (_to.code.length > 0) {
            try IERC721Receiver(_to).onERC721Received(msg.sender, _from, _tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            }
            catch (bytes memory reason){
                if (reason.length == 0){
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                }
                else {
                    string memory revertReason = abi.decode(reason, (string));
                    revert(revertReason);
                }
            }
        }
        else {
            return true;
        }
    }

    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }
}

