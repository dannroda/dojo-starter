use dojo_starter::models::{Direction, Position, Vec2};

// define the interface
#[starknet::interface]
pub trait IActions<T> {
    fn reset_spawn(ref self: T);
    fn spawn(ref self: T);
    fn move(ref self: T, direction: Direction, magnitude: u32);
    fn move_to(ref self: T, vec: Vec2);
}

// dojo decorator
#[dojo::contract]
pub mod actions {
    use dojo::event::EventStorage;
    use dojo::model::ModelStorage;
    use dojo_starter::models::{Moves, Vec2};
    use starknet::{ContractAddress, get_caller_address};
    use super::{Direction, IActions, Position, next_position};

    #[derive(Copy, Drop, Serde)]
    #[dojo::event]
    pub struct Moved {
        #[key]
        pub player: ContractAddress,
        pub direction: Direction,
    }

    #[abi(embed_v0)]
    impl ActionsImpl of IActions<ContractState> {
        fn reset_spawn(ref self: ContractState) {
            // Get the default world.
            let mut world = self.world_default();

            // Get the address of the current caller, possibly the player's address.
            let player = get_caller_address();
            // Retrieve the player's current position from the world.
            //let position: Position = world.read_model(player);

            // Update the world state with the new data.

            // 1. Move the player's position to 0 in both the x and y direction.
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

            // Update the world state with the new data.

            // 1. Move the player's position to position (10, 10).
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
        fn move(ref self: ContractState, direction: Direction, magnitude: u32) {
            // Get the address of the current caller, possibly the player's address.

            let mut world = self.world_default();

            let player = get_caller_address();

            // Retrieve the player's current position and moves data from the world.
            let position: Position = world.read_model(player);
            let mut moves: Moves = world.read_model(player);
            // if player hasn't spawn, read returns model default values. This leads to sub overflow
            // afterwards.
            // Plus it's generally considered as a good pratice to fast-return on matching
            // conditions.
            if !moves.can_move {
                return;
            }

            // Deduct one from the player's remaining moves.
            moves.remaining -= 1;

            // Update the last direction the player moved in.
            moves.last_direction = Option::Some(direction);

            // Calculate the player's next position based on the provided direction and magnitude.
            // Use magnitude directly since it's now a u32 instead of Option<u32>
            let actual_magnitude = if magnitude == 0 {
                1
            } else {
                magnitude
            };
            let next = next_position(position, moves.last_direction, actual_magnitude);

            // Write the new position to the world.
            world.write_model(@next);

            // Write the new moves to the world.
            world.write_model(@moves);

            // Emit an event to the world to notify about the player's move.
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
