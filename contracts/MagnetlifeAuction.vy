# @version ^0.3.7


from vyper.interfaces import ERC20
from vyper.interfaces import ERC165
from vyper.interfaces import ERC721

implements: ERC721
implements: ERC165

# Interface for the contract called by safeTransferFrom()
interface ERC721Receiver:
    def onERC721Received(
        operator: address, sender: address, tokenId: uint256, data: Bytes[1024]
    ) -> bytes4: nonpayable


# @dev Emits when ownership of any NFT changes by any mechanism.
event Transfer:
    _from: indexed(address)
    _to: indexed(address)
    _tokenId: indexed(uint256)


# @dev This emits when the approved address for an NFT is changed or reaffirmed.
event Approval:
    _owner: indexed(address)
    _approved: indexed(address)
    _tokenId: indexed(uint256)


# @dev This emits when an operator is enabled or disabled for an owner.
event ApprovalForAll:
    _owner: indexed(address)
    _operator: indexed(address)
    _approved: bool


IDENTITY_PRECOMPILE: constant(
    address
) = 0x0000000000000000000000000000000000000004

# Metadata
symbol: public(String[32])
name: public(String[32])

# Permissions
owner: public(address)

# URI
base_uri: public(String[128])
contract_uri: String[128]

# NFT Data
ids_by_owner: HashMap[address, uint256[]]
id_to_index: HashMap[uint256, uint256]
token_count: uint256

owned_tokens: HashMap[uint256, address]  # @dev NFT ID to the address that owns it
token_approvals: HashMap[uint256, address]  # @dev NFT ID to approved address
operator_approvals: HashMap[address, HashMap[address, bool]]  # @dev Owner address to mapping of operator addresses

# @dev Static list of supported ERC165 interface ids
SUPPORTED_INTERFACES: constant(bytes4[5]) = [
    0x01ffc9a7,  # ERC165
    0x80ac58cd,  # ERC721
    0x150b7a02,  # ERC721TokenReceiver
    0x780e9d63,  # ERC721Enumerable
    0x5b5e139f,  # ERC721Metadata
]

# Custom NFT
revealed: public(bool)
default_uri: public(String[150])

MAX_SUPPLY: constant(uint256) = 300
MAX_PREMINT: constant(uint256) = 20
MAX_MINT_PER_TX: constant(uint256) = 3
COST: constant(uint256) = as_wei_value(0.1, "ether")

al_mint_started: public(bool)
al_signer: public(address)
minter: public(address)
al_mint_amount: public(HashMap[address, uint256])


@external
def __init__(preminters: address[MAX_PREMINT]):
    self.symbol = "MAGNET"
    self.name = "The Magnet"
    self.owner = msg.sender
    self.contract_uri = "https://example.com/contract_uri"
    self.default_uri = "https://example.com/default_uri"
    self.al_mint_started = False
    self.al_signer = msg.sender
    self.minter = msg.sender

    for i in range(MAX_PREMINT):
        token_id: uint256 = self.token_count + 1
        self.token_count = token_id
        self._mint(msg.sender, token_id)
        self.al_mint_amount[msg.sender] += 1
        self.al_mint_started = True

    for i in range(len(preminters)):
        pre_minter: address = preminters[i]
        token_id = self.token_count + 1
        self.token_count = token_id
        self._mint(pre_minter, token_id)
        self.al_mint_amount[pre_minter] += 1
        self.al_mint_started = True


@external
def supportsInterface(interfaceId: bytes4) -> bool:
    """
    @notice Check if a contract supports a given interface
    @param interfaceId The interface ID to check
    @return True if the interface is supported, False otherwise
    """
    for supportedInterface in self.SUPPORTED_INTERFACES:
        if supportedInterface == interfaceId:
            return True
    return False


@external
def balanceOf(owner: address) -> uint256:
    """
    @notice Get the balance of NFTs owned by an address
    @param owner The address to query
    @return The number of NFTs owned by the address
    """
    return len(self.ids_by_owner[owner])


@external
def ownerOf(tokenId: uint256) -> address:
    """
    @notice Get the owner of an NFT
    @param tokenId The ID of the NFT
    @return The address of the owner
    """
    assert tokenId <= self.token_count, "Invalid token ID"
    owner = self.owned_tokens[tokenId]
    assert owner != address(0), "Nonexistent token"
    return owner


@external
def transferFrom(from: address, to: address, tokenId: uint256):
    """
    @notice Transfer the ownership of an NFT
    @param from The current owner of the NFT
    @param to The new owner of the NFT
    @param tokenId The ID of the NFT to transfer
    """
    assert self._isApprovedOrOwner(msg.sender, tokenId), "Not approved or owner"
    self._transfer(from, to, tokenId)


@external
def approve(approved: address, tokenId: uint256):
    """
    @notice Approve an address to manage the NFT
    @param approved The address to approve
    @param tokenId The ID of the NFT to approve
    """
    owner = self.ownerOf(tokenId)
    assert msg.sender == owner, "Not the owner"
    self.token_approvals[tokenId] = approved
    emit Approval(owner, approved, tokenId)


@external
def setApprovalForAll(operator: address, approved: bool):
    """
    @notice Set or unset approval for an operator to manage all NFTs
    @param operator The operator to approve or unapprove
    @param approved True to approve, False to unapprove
    """
    self.operator_approvals[msg.sender][operator] = approved
    emit ApprovalForAll(msg.sender, operator, approved)


@external
def getApproved(tokenId: uint256) -> address:
    """
    @notice Get the approved address for an NFT
    @param tokenId The ID of the NFT
    @return The address approved to manage the NFT
    """
    assert tokenId <= self.token_count, "Invalid token ID"
    return self.token_approvals[tokenId]


@external
def isApprovedForAll(owner: address, operator: address) -> bool:
    """
    @notice Check if an operator is approved to manage all NFTs of an owner
    @param owner The owner of the NFTs
    @param operator The operator to check
    @return True if the operator is approved for all N