// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract AttentionEscrow {

    enum State { Created, Approved, Completed, Refunded, Rejected }

    struct Order {
        string orderId;   // Encrypted or hashed order ID, stored on-chain
        State state;      // The state of the order
        uint256 amount;   // The amount locked in escrow
        uint256 expiry;   // Expiry time for the order
        address recipient; // Recipient of the order amount upon completion
    }

    mapping(string => Order) public orders;

    event OrderCreated(string indexed orderId, uint256 amount, uint256 expiry, address recipient);
    event OrderApproved(string indexed orderId);
    event OrderCompleted(string indexed orderId);
    event OrderRefunded(string indexed orderId);
    event OrderRejected(string indexed orderId);

    modifier orderExists(string memory _orderId) {
        require(orders[_orderId].amount > 0, "Order does not exist");
        _;
    }

    modifier notExpired(string memory _orderId) {
        require(block.timestamp <= orders[_orderId].expiry, "Order has expired");
        _;
    }

    modifier inState(string memory _orderId, State _state) {
        require(orders[_orderId].state == _state, "Order is not in the correct state");
        _;
    }

    // Create a new order with the orderId, state is set to Created
    function createOrder(string memory _orderId, uint256 _expiry, address _recipient) external payable {
        require(bytes(_orderId).length > 0, "Order ID cannot be empty");
        require(msg.value > 0, "Must send funds to create order");
        require(_expiry > block.timestamp, "Expiry must be in the future");
        require(_recipient != address(0), "Recipient address cannot be zero");

        orders[_orderId] = Order({
            orderId: _orderId,
            state: State.Created,
            amount: msg.value,
            expiry: _expiry,
            recipient: _recipient
        });

        emit OrderCreated(_orderId, msg.value, _expiry, _recipient);
    }

    // Approve the order by the sender who created it
    function approveOrder(string memory _orderId) external orderExists(_orderId) inState(_orderId, State.Created) {
        orders[_orderId].state = State.Approved;
        emit OrderApproved(_orderId);
    }

    // Reject the order if needed
    function rejectOrder(string memory _orderId) external orderExists(_orderId) inState(_orderId, State.Created) {
        orders[_orderId].state = State.Rejected;
        emit OrderRejected(_orderId);
    }

    // Complete the order and transfer funds to the recipient
    function completeOrder(string memory _orderId) external orderExists(_orderId) inState(_orderId, State.Approved) notExpired(_orderId) {
        Order storage order = orders[_orderId];
        order.state = State.Completed;

        (bool sent, ) = order.recipient.call{value: order.amount}("");
        require(sent, "Failed to send funds to recipient");

        emit OrderCompleted(_orderId);
    }

    // Refund the order if it has expired and hasn't been completed
    function refundOrder(string memory _orderId, address _depositor) external orderExists(_orderId) inState(_orderId, State.Created) {
        require(block.timestamp > orders[_orderId].expiry, "Order has not expired yet");

        Order storage order = orders[_orderId];
        order.state = State.Refunded;

        (bool sent, ) = _depositor.call{value: order.amount}("");
        require(sent, "Failed to refund funds to depositor");

        emit OrderRefunded(_orderId);
    }

    // Get order state
    function getOrderState(string memory _orderId) external view orderExists(_orderId) returns (State) {
        return orders[_orderId].state;
    }

    // Get the state of multiple orders in a batch
    function getOrderStates(string[] memory _orderIds) external view returns (State[] memory) {
        State[] memory states = new State[](_orderIds.length);
        
        for (uint256 i = 0; i < _orderIds.length; i++) {
            string memory orderId = _orderIds[i];
            require(orders[orderId].amount > 0, "One of the orders does not exist");
            states[i] = orders[orderId].state;
        }
        
        return states;
    }
}