use dojo_starter::models::{Direction, Position, PositionSigned, Vec2, Vec2Signed, U32IntoI32};
use starknet::{ClassHash, EthAddress, ContractAddress};

// define the interface
#[starknet::interface]
pub trait IActions<T> {
    fn reset_spawn(ref self: T);
    fn spawn(ref self: T);
    fn move(ref self: T, direction: Direction, magnitude: Option<u32>);
    fn move_signed(ref self: T, direction: Direction, magnitude: Option<u32>);
    fn move_to(ref self: T, vec: Vec2);
    fn move_to_signed(ref self: T, vec: Vec2Signed);
    fn validate(
        ref self: T,
        val_i8: i8,
        val_i16: i16,
        val_i32: i32,
        val_i64: i64,
        val_i128: i128,
        val_u8: u8,
        val_u16: u16,
        val_u32: u32,
        val_u64: u64,
        val_u128: u128,
        val_u256: u256,
        val_bool: bool,
        val_felt252: felt252,
        val_class_hash: ClassHash,
        val_contract_address: ContractAddress,
        val_eth_address: EthAddress
    );
    fn validate_i8(ref self: T, val: i8);
    fn validate_i16(ref self: T, val: i16);
    fn validate_i32(ref self: T, val: i32);
    fn validate_i64(ref self: T, val: i64);
    fn validate_i128(ref self: T, val: i128);
    fn validate_u8(ref self: T, val: u8);
    fn validate_u16(ref self: T, val: u16);
    fn validate_u32(ref self: T, val: u32);
    fn validate_u64(ref self: T, val: u64);
    fn validate_u128(ref self: T, val: u128);
    fn validate_u256(ref self: T, val: u256);
    fn validate_bool(ref self: T, val: bool);
    fn validate_felt252(ref self: T, val: felt252);
    fn validate_class_hash(ref self: T, val: ClassHash);
    fn validate_contract_address(ref self: T, val: ContractAddress);
    fn validate_eth_address(ref self: T, val: EthAddress);
}

// dojo decorator
#[dojo::contract]
pub mod actions {
    use dojo::event::EventStorage;
    use dojo::model::ModelStorage;
    use dojo_starter::models::{Moves, Vec2, Vec2Signed};
    use starknet::{ContractAddress, get_caller_address, ClassHash, EthAddress};
    use super::{Direction, IActions, Position, PositionSigned, next_position, next_position_signed};

    #[derive(Copy, Drop, Serde)]
    #[dojo::event]
    pub struct Moved {
        #[key]
        pub player: ContractAddress,
        pub direction: Direction,
    }

    #[derive(Copy, Drop, Serde)]
    #[dojo::event]
    pub struct Validated {
        #[key]
        pub player: ContractAddress,
        pub val_i8: i8,
        pub val_i16: i16,
        pub val_i32: i32,
        pub val_i64: i64,
        pub val_i128: i128,
        pub val_u8: u8,
        pub val_u16: u16,
        pub val_u32: u32,
        pub val_u64: u64,
        pub val_u128: u128,
        pub val_u256: u256,
        pub val_bool: bool,
        pub val_felt252: felt252,
        pub val_class_hash: ClassHash,
        pub val_contract_address: ContractAddress,
        pub val_eth_address: EthAddress,
    }

    #[derive(Copy, Drop, Serde)]
    #[dojo::event]
    pub struct ValidatedI8 {
        #[key]
        pub player: ContractAddress,
        pub val: i8,
    }

    #[derive(Copy, Drop, Serde)]
    #[dojo::event]
    pub struct ValidatedI16 {
        #[key]
        pub player: ContractAddress,
        pub val: i16,
    }

    #[derive(Copy, Drop, Serde)]
    #[dojo::event]
    pub struct ValidatedI32 {
        #[key]
        pub player: ContractAddress,
        pub val: i32,
    }

    #[derive(Copy, Drop, Serde)]
    #[dojo::event]
    pub struct ValidatedI64 {
        #[key]
        pub player: ContractAddress,
        pub val: i64,
    }

    #[derive(Copy, Drop, Serde)]
    #[dojo::event]
    pub struct ValidatedI128 {
        #[key]
        pub player: ContractAddress,
        pub val: i128,
    }

    #[derive(Copy, Drop, Serde)]
    #[dojo::event]
    pub struct ValidatedU8 {
        #[key]
        pub player: ContractAddress,
        pub val: u8,
    }

    #[derive(Copy, Drop, Serde)]
    #[dojo::event]
    pub struct ValidatedU16 {
        #[key]
        pub player: ContractAddress,
        pub val: u16,
    }

    #[derive(Copy, Drop, Serde)]
    #[dojo::event]
    pub struct ValidatedU32 {
        #[key]
        pub player: ContractAddress,
        pub val: u32,
    }

    #[derive(Copy, Drop, Serde)]
    #[dojo::event]
    pub struct ValidatedU64 {
        #[key]
        pub player: ContractAddress,
        pub val: u64,
    }

    #[derive(Copy, Drop, Serde)]
    #[dojo::event]
    pub struct ValidatedU128 {
        #[key]
        pub player: ContractAddress,
        pub val: u128,
    }

    #[derive(Copy, Drop, Serde)]
    #[dojo::event]
    pub struct ValidatedU256 {
        #[key]
        pub player: ContractAddress,
        pub val: u256,
    }

    #[derive(Copy, Drop, Serde)]
    #[dojo::event]
    pub struct ValidatedBool {
        #[key]
        pub player: ContractAddress,
        pub val: bool,
    }

    #[derive(Copy, Drop, Serde)]
    #[dojo::event]
    pub struct ValidatedFelt252 {
        #[key]
        pub player: ContractAddress,
        pub val: felt252,
    }

    #[derive(Copy, Drop, Serde)]
    #[dojo::event]
    pub struct ValidatedClassHash {
        #[key]
        pub player: ContractAddress,
        pub val: ClassHash,
    }

    #[derive(Copy, Drop, Serde)]
    #[dojo::event]
    pub struct ValidatedContractAddress {
        #[key]
        pub player: ContractAddress,
        pub val: ContractAddress,
    }

    #[derive(Copy, Drop, Serde)]
    #[dojo::event]
    pub struct ValidatedEthAddress {
        #[key]
        pub player: ContractAddress,
        pub val: EthAddress,
    }


    #[abi(embed_v0)]
    impl ActionsImpl of IActions<ContractState> {
        fn reset_spawn(ref self: ContractState) {
            // Get the default world.
            let mut world = self.world_default();

            // Get the address of the current caller, possibly the player's address.
            let player = get_caller_address();

            // 1. Move the player's position to 0 in both the x and y direction (unsigned).
            let new_position = Position { player, vec: Vec2 { x: 0, y: 0 } };

            // Write the new position to the world.
            world.write_model(@new_position);

            // 2. Set the player's remaining moves to 100.
            let moves = Moves {
                player, remaining: 100, last_direction: Option::None, can_move: true,
            };

            // Write the new moves to the world.
            world.write_model(@moves);
        }

        fn spawn(ref self: ContractState) {
            // Get the default world.
            let mut world = self.world_default();

            // Get the address of the current caller, possibly the player's address.
            let player = get_caller_address();
            // Retrieve the player's current position from the world.
            let position: Position = world.read_model(player);

            // 1. Move the player's position to position (10, 10) using unsigned Vec2.
            let new_position = Position {
                player, vec: Vec2 { x: position.vec.x + 10, y: position.vec.y + 10 },
            };

            // Write the new position to the world.
            world.write_model(@new_position);

            // 2. Set the player's remaining moves to 100.
            let moves = Moves {
                player, remaining: 100, last_direction: Option::None, can_move: true,
            };

            // Write the new moves to the world.
            world.write_model(@moves);
        }

        // Implementation of the move function for the ContractState struct.
        fn move(ref self: ContractState, direction: Direction, magnitude: Option<u32>) {
            // Get the address of the current caller, possibly the player's address.

            let mut world = self.world_default();

            let player = get_caller_address();

            // Retrieve the player's current position and moves data from the world.
            let position: Position = world.read_model(player);
            let mut moves: Moves = world.read_model(player);
            if !moves.can_move {
                return;
            }

            // Deduct one from the player's remaining moves.
            moves.remaining -= 1;

            // Update the last direction the player moved in.
            moves.last_direction = Option::Some(direction);

            // Calculate the player's next position based on the provided direction and magnitude.
            let actual_magnitude = match magnitude {
                Option::Some(m) => { if m == 0 { 1 } else { m } },
                Option::None(()) => 1,
            };
            let next = next_position(position, moves.last_direction, actual_magnitude);

            // Write the new position to the world.
            world.write_model(@next);

            // Write the new moves to the world.
            world.write_model(@moves);

            // Emit an event to the world to notify about the player's move.
            world.emit_event(@Moved { player, direction });
        }

        // Signed equivalent of move
        fn move_signed(ref self: ContractState, direction: Direction, magnitude: Option<u32>) {
            let mut world = self.world_default();
            let player = get_caller_address();
            let position: PositionSigned = world.read_model(player);
            let mut moves: Moves = world.read_model(player);
            if !moves.can_move { return; }
            moves.remaining -= 1;
            moves.last_direction = Option::Some(direction);
            let actual_magnitude = match magnitude {
                Option::Some(m) => { if m == 0 { 1 } else { m } },
                Option::None(()) => 1,
            };
            let next = next_position_signed(position, moves.last_direction, actual_magnitude);
            world.write_model(@next);
            world.write_model(@moves);
            world.emit_event(@Moved { player, direction });
        }

        // Implementation of the move_to function for the ContractState struct.
        fn move_to(ref self: ContractState, vec: Vec2) {
            let mut world = self.world_default();

            let player = get_caller_address();

            let new_position = Position { player, vec };
            let mut moves: Moves = world.read_model(player);

            world.write_model(@new_position);
            let new_moves = Moves {
                player, remaining: moves.remaining, last_direction: Option::None, can_move: moves.can_move,
            };

            world.write_model(@new_moves);
        }

        // Signed equivalent of move_to
        fn move_to_signed(ref self: ContractState, vec: Vec2Signed) {
            let mut world = self.world_default();
            let player = get_caller_address();
            let new_position = PositionSigned { player, vec };
            let mut moves: Moves = world.read_model(player);
            world.write_model(@new_position);
            let new_moves = Moves { player, remaining: moves.remaining, last_direction: Option::None, can_move: moves.can_move };
            world.write_model(@new_moves);
        }

        fn validate(
            ref self: ContractState,
            val_i8: i8,
            val_i16: i16,
            val_i32: i32,
            val_i64: i64,
            val_i128: i128,
            val_u8: u8,
            val_u16: u16,
            val_u32: u32,
            val_u64: u64,
            val_u128: u128,
            val_u256: u256,
            val_bool: bool,
            val_felt252: felt252,
            val_class_hash: ClassHash,
            val_contract_address: ContractAddress,
            val_eth_address: EthAddress
        ) {
            let mut world = self.world_default();
            let player = get_caller_address();
            world.emit_event(
                @Validated {
                    player,
                    val_i8,
                    val_i16,
                    val_i32,
                    val_i64,
                    val_i128,
                    val_u8,
                    val_u16,
                    val_u32,
                    val_u64,
                    val_u128,
                    val_u256,
                    val_bool,
                    val_felt252,
                    val_class_hash,
                    val_contract_address,
                    val_eth_address,
                }
            );
        }

        fn validate_i8(ref self: ContractState, val: i8) {
            let mut world = self.world_default();
            let player = get_caller_address();
            world.emit_event(@ValidatedI8 { player, val });
        }

        fn validate_i16(ref self: ContractState, val: i16) {
            let mut world = self.world_default();
            let player = get_caller_address();
            world.emit_event(@ValidatedI16 { player, val });
        }

        fn validate_i32(ref self: ContractState, val: i32) {
            let mut world = self.world_default();
            let player = get_caller_address();
            world.emit_event(@ValidatedI32 { player, val });
        }

        fn validate_i64(ref self: ContractState, val: i64) {
            let mut world = self.world_default();
            let player = get_caller_address();
            world.emit_event(@ValidatedI64 { player, val });
        }

        fn validate_i128(ref self: ContractState, val: i128) {
            let mut world = self.world_default();
            let player = get_caller_address();
            world.emit_event(@ValidatedI128 { player, val });
        }

        fn validate_u8(ref self: ContractState, val: u8) {
            let mut world = self.world_default();
            let player = get_caller_address();
            world.emit_event(@ValidatedU8 { player, val });
        }

        fn validate_u16(ref self: ContractState, val: u16) {
            let mut world = self.world_default();
            let player = get_caller_address();
            world.emit_event(@ValidatedU16 { player, val });
        }

        fn validate_u32(ref self: ContractState, val: u32) {
            let mut world = self.world_default();
            let player = get_caller_address();
            world.emit_event(@ValidatedU32 { player, val });
        }

        fn validate_u64(ref self: ContractState, val: u64) {
            let mut world = self.world_default();
            let player = get_caller_address();
            world.emit_event(@ValidatedU64 { player, val });
        }

        fn validate_u128(ref self: ContractState, val: u128) {
            let mut world = self.world_default();
            let player = get_caller_address();
            world.emit_event(@ValidatedU128 { player, val });
        }

        fn validate_u256(ref self: ContractState, val: u256) {
            let mut world = self.world_default();
            let player = get_caller_address();
            world.emit_event(@ValidatedU256 { player, val });
        }

        fn validate_bool(ref self: ContractState, val: bool) {
            let mut world = self.world_default();
            let player = get_caller_address();
            world.emit_event(@ValidatedBool { player, val });
        }

        fn validate_felt252(ref self: ContractState, val: felt252) {
            let mut world = self.world_default();
            let player = get_caller_address();
            world.emit_event(@ValidatedFelt252 { player, val });
        }

        fn validate_class_hash(ref self: ContractState, val: ClassHash) {
            let mut world = self.world_default();
            let player = get_caller_address();
            world.emit_event(@ValidatedClassHash { player, val });
        }

        fn validate_contract_address(ref self: ContractState, val: ContractAddress) {
            let mut world = self.world_default();
            let player = get_caller_address();
            world.emit_event(@ValidatedContractAddress { player, val });
        }

        fn validate_eth_address(ref self: ContractState, val: EthAddress) {
            let mut world = self.world_default();
            let player = get_caller_address();
            world.emit_event(@ValidatedEthAddress { player, val });
        }
    }

    #[generate_trait]
    impl InternalImpl of InternalTrait {
        /// Use the default namespace "dojo_starter". This function is handy since the ByteArray
        /// can't be const.
        fn world_default(self: @ContractState) -> dojo::world::WorldStorage {
            self.world(@"dojo_starter")
        }
    }
}

// Define function like this:
fn next_position(mut position: Position, direction: Option<Direction>, magnitude: u32) -> Position {
    // magnitude is already handled in the move function
    match direction {
        Option::None => { return position; },
        Option::Some(d) => match d {
            Direction::Left => { position.vec.x -= magnitude; },
            Direction::Right => { position.vec.x += magnitude; },
            Direction::Up => { position.vec.y -= magnitude; },
            Direction::Down => { position.vec.y += magnitude; },
        },
    }
    position
}

// Define function for signed positions:
fn next_position_signed(
    mut position: PositionSigned, direction: Option<Direction>, magnitude: u32
) -> PositionSigned {
    // magnitude is already handled in the move function
    let magnitude_i32: i32 = magnitude.into();
    match direction {
        Option::None => { return position; },
        Option::Some(d) => match d {
            Direction::Left => { position.vec.x -= magnitude_i32; },
            Direction::Right => { position.vec.x += magnitude_i32; },
            Direction::Up => { position.vec.y -= magnitude_i32; },
            Direction::Down => { position.vec.y += magnitude_i32; },
        },
    }
    position
}
