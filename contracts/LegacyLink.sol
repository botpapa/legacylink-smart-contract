// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/access/Ownable.sol";


contract LegacyLink is Ownable {

    struct Letter {
        // encoded letter data
        string payload;

        // users' addresses who can have access to the decoded data
        address[] receivers;

        address creator;
    }

    struct Receiver {
        // IDs of the letters user is associated wtth
        uint[] letters;

        // letterId to bool whether user receives that letter
        mapping(uint => bool) willReceive;

        // letterId to bool whether user has already received that letter
        mapping(uint => bool) received;
    }

    // mapping letterId to the letter info
    mapping(uint => Letter) private letters;
    uint private lettersCounter = 1;

    mapping(address => Receiver) lettersReceiversMapping;

    // Contract admins
    mapping(address => bool) admins;

    constructor() {
        // setting contract deployer as admin
        admins[msg.sender] = true;
    }


    /**
     * @dev modifier that is used to grant access to certain features
     */
    modifier onlyAdmin() {
        require(admins[msg.sender], "You're not an admin.");
        _;
    }

    /**
     * @notice Flip admin status
     */
    function flipAdminStatus(address walletAddress) external onlyOwner returns(bool) {
        admins[walletAddress] = !admins[walletAddress];
        return admins[walletAddress];
    }


    //////////////
    //          //
    //   Core   //
    //          //
    //////////////

    function addLetterForReceivers(uint letterId, address[] memory _receivers) internal {
        // Mapping receivers to letterIds
        for (uint i = 0; i < _receivers.length; i++) {
            lettersReceiversMapping[_receivers[i]].letters.push(letterId);
            lettersReceiversMapping[_receivers[i]].willReceive[letterId] = true;
        }
    }

    function removeLetterForReceivers(uint letterId, address[] memory _receivers) internal {
        // Mapping receivers to letterIds
        for (uint i = 0; i < _receivers.length; i++) {
             lettersReceiversMapping[_receivers[i]].willReceive[letterId] = false;
        }
    }

    /**
     * @notice Create letter
     */
    function createLetter(string memory _payload, address[] memory _receivers) public returns(uint) {
        letters[lettersCounter] = Letter(
            {
                payload: _payload,
                receivers: _receivers,
                creator: msg.sender
            }
        );
        addLetterForReceivers(lettersCounter, _receivers);

        lettersCounter += 1;
        return lettersCounter - 1;
    }

    /**
     * @notice Update letter
     */
    function updateLetter(uint letterId, string memory _payload, address[] memory _receivers) public {
        require(letters[letterId].creator == msg.sender, "You cannot update this letter as it does not belong to you.");

        removeLetterForReceivers(letterId, letters[letterId].receivers);
        letters[letterId] = Letter(
            {
                payload: _payload,
                receivers: _receivers,
                creator: msg.sender
            }
        );
        addLetterForReceivers(letterId, _receivers);

    }

    /**
     * @notice Delete letter
     */
    function deleteLetter(uint letterId) public {
        require(letters[letterId].creator == msg.sender, "You cannot delete this letter as it does not belong to you.");

        string memory _payload;
        address[] memory _receivers;

        removeLetterForReceivers(letterId, letters[letterId].receivers);
        letters[letterId] = Letter(
            {
                payload: _payload,
                receivers: _receivers,
                creator: address(0)
            }
        );
    }

    /**
     * @notice Get letter
     */
    function getLetter(uint letterId) public view returns(Letter memory) {
        return letters[letterId];
    }

    /**
     * @notice Get letters
     */
    function getLetters(address user) public view returns(uint[] memory) {
        uint[] memory _letters = new uint[](lettersCounter);
        uint _counter = 0;

        for (uint i = 0; i < lettersCounter; i++) {
            if (letters[i].creator == user) {
                _letters[_counter] = i;
                _counter += 1;
            }
        }

        return _letters;
    }

    /**
     * @notice Get received letter
     */
    function getReceivedLetters(address user) public view returns(uint[] memory) {
        uint[] memory _letters = new uint[](lettersReceiversMapping[user].letters.length);
        uint _counter = 0;

        for (uint i = 0; i < lettersReceiversMapping[user].letters.length; i++) {
            uint _letterId = lettersReceiversMapping[user].letters[i];

            if (lettersReceiversMapping[user].received[_letterId] == true) {
                _letters[_counter] = _letterId;
                _counter += 1;
            }
        }

        return _letters;
    }

    /**
     * @notice Send letter
     */
    function sendLetter(uint letterId) public {
        for (uint i = 0; i < letters[letterId].receivers.length; i++) {
            address _receiver = letters[letterId].receivers[i];

            lettersReceiversMapping[_receiver].received[letterId] = true;
        }
    }

}
