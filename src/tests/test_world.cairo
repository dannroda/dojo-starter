#[cfg(test)]
mod tests {
    use dojo_cairo_test::WorldStorageTestTrait;
    use dojo::model::{ModelStorage, ModelStorageTest, world};
    use dojo::world::WorldStorageTrait;
    use dojo_cairo_test::{
        spawn_test_world, NamespaceDef, TestResource, ContractDefTrait, ContractDef,
    };

    use dojo_starter::systems::actions::{actions, IActionsDispatcher, IActionsDispatcherTrait};
    use dojo_starter::models::{Position, m_Position, PositionSigned, m_PositionSigned, Moves, m_Moves, Direction, Vec2, Vec2Signed};

    fn namespace_def() -> NamespaceDef {
        let ndef = NamespaceDef {
            namespace: "dojo_starter",
            resources: [
                TestResource::Model(m_Position::TEST_CLASS_HASH.into()),
                TestResource::Model(m_PositionSigned::TEST_CLASS_HASH.into()),
                TestResource::Model(m_Moves::TEST_CLASS_HASH.into()),
                TestResource::Event(actions::e_Moved::TEST_CLASS_HASH.into()),
                TestResource::Contract(actions::TEST_CLASS_HASH.into()),
            ]
                .span(),
        };

        ndef
    }

    fn contract_defs() -> Span<ContractDef> {
        [
            ContractDefTrait::new(@"dojo_starter", @"actions")
                .with_writer_of([dojo::utils::bytearray_hash(@"dojo_starter")].span())
        ]
            .span()
    }

    #[test]
    fn test_world_test_set() {
        // Initialize test environment
        let caller = starknet::contract_address_const::<0x0>();
        let ndef = namespace_def();

        // Register the resources.
        let mut world = spawn_test_world(world::TEST_CLASS_HASH, [ndef].span());

        // Ensures permissions and initializations are synced.
        world.sync_perms_and_inits(contract_defs());

        // Test initial position
        let mut position: Position = world.read_model(caller);
        assert(position.vec.x == 0 && position.vec.y == 0, 'initial position wrong');

        // Test write_model_test
        position.vec.x = 122;
        position.vec.y = 88;

        world.write_model_test(@position);

        let mut position: Position = world.read_model(caller);
        assert(position.vec.y == 88, 'write_value_from_id failed');

        // Test model deletion
        world.erase_model(@position);
        let position: Position = world.read_model(caller);
        assert(position.vec.x == 0 && position.vec.y == 0, 'erase_model failed');
    }

    #[test]
    #[available_gas(30000000)]
    fn test_move() {
        let caller = starknet::contract_address_const::<0x0>();

        let ndef = namespace_def();
        let mut world = spawn_test_world(world::TEST_CLASS_HASH, [ndef].span());
        world.sync_perms_and_inits(contract_defs());

        let (contract_address, _) = world.dns(@"actions").unwrap();
        let actions_system = IActionsDispatcher { contract_address };

        actions_system.spawn();
        let initial_moves: Moves = world.read_model(caller);
        let initial_position: Position = world.read_model(caller);

        assert(
            initial_position.vec.x == 10 && initial_position.vec.y == 10, 'wrong initial position',
        );

        actions_system.move(Direction::Right(()).into(), Option::Some(1));

        let moves: Moves = world.read_model(caller);
        let right_dir_felt: felt252 = Direction::Right(()).into();

        assert(moves.remaining == initial_moves.remaining - 1, 'moves is wrong');
        assert(moves.last_direction.unwrap().into() == right_dir_felt, 'last direction is wrong');

        let new_position: Position = world.read_model(caller);
        assert(new_position.vec.x == initial_position.vec.x + 1, 'position x is wrong');
        assert(new_position.vec.y == initial_position.vec.y, 'position y is wrong');
    }

    #[test]
    #[available_gas(30000000)]
    fn test_move_with_magnitude() {
        let caller = starknet::contract_address_const::<0x0>();

        let ndef = namespace_def();
        let mut world = spawn_test_world([ndef].span());
        world.sync_perms_and_inits(contract_defs());

        let (contract_address, _) = world.dns(@"actions").unwrap();
        let actions_system = IActionsDispatcher { contract_address };

        actions_system.spawn();
        let initial_moves: Moves = world.read_model(caller);
        let initial_position: Position = world.read_model(caller);

        // Test with magnitude 3
        let magnitude = 3;
        actions_system.move(Direction::Right(()).into(), Option::Some(magnitude));

        let moves: Moves = world.read_model(caller);
        let right_dir_felt: felt252 = Direction::Right(()).into();

        assert(moves.remaining == initial_moves.remaining - 1, 'moves is wrong');
        assert(moves.last_direction.unwrap().into() == right_dir_felt, 'last direction is wrong');

        let new_position: Position = world.read_model(caller);
        assert(new_position.vec.x == initial_position.vec.x + magnitude, 'position x is wrong');
        assert(new_position.vec.y == initial_position.vec.y, 'position y is wrong');

        // Test with a different direction and magnitude
        let magnitude2 = 5;
        actions_system.move(Direction::Down(()).into(), Option::Some(magnitude2));

        let moves2: Moves = world.read_model(caller);
        let down_dir_felt: felt252 = Direction::Down(()).into();

        assert(moves2.remaining == moves.remaining - 1, 'moves is wrong');
        assert(moves2.last_direction.unwrap().into() == down_dir_felt, 'last direction is wrong');

        let final_position: Position = world.read_model(caller);
        assert(final_position.vec.x == new_position.vec.x, 'position x is wrong');
        assert(final_position.vec.y == new_position.vec.y + magnitude2, 'position y is wrong');
    }

    #[test]
    #[available_gas(30000000)]
    fn test_move_with_zero_magnitude() {
        let caller = starknet::contract_address_const::<0x0>();

        let ndef = namespace_def();
        let mut world = spawn_test_world([ndef].span());
        world.sync_perms_and_inits(contract_defs());

        let (contract_address, _) = world.dns(@"actions").unwrap();
        let actions_system = IActionsDispatcher { contract_address };

        actions_system.spawn();
        let initial_position: Position = world.read_model(caller);

        // Test with magnitude 0 (should default to 1)
        actions_system.move(Direction::Right(()).into(), Option::Some(0));

        let new_position: Position = world.read_model(caller);
        // Since magnitude 0 should default to 1, we expect position.x to increase by 1
        assert(new_position.vec.x == initial_position.vec.x + 1, 'position x is wrong');
        assert(new_position.vec.y == initial_position.vec.y, 'position y is wrong');
    }

    #[test]
    #[available_gas(30000000)]
    fn test_move_with_null_magnitude() {
        let caller = starknet::contract_address_const::<0x0>();

        let ndef = namespace_def();
        let mut world = spawn_test_world([ndef].span());
        world.sync_perms_and_inits(contract_defs());

        let (contract_address, _) = world.dns(@"actions").unwrap();
        let actions_system = IActionsDispatcher { contract_address };

        actions_system.spawn();
        let initial_position: Position = world.read_model(caller);

        // Test with null magnitude (now using default value 1)
        actions_system.move(Direction::Right(()).into(), Option::None(()));

        let new_position: Position = world.read_model(caller);
        // Since null magnitude should default to 1, we expect position.x to increase by 1
        assert(new_position.vec.x == initial_position.vec.x + 1, 'position x is wrong');
        assert(new_position.vec.y == initial_position.vec.y, 'position y is wrong');
    }

    #[test]
    #[available_gas(30000000)]
    fn test_move_to() {
        let caller = starknet::contract_address_const::<0x0>();

        let ndef = namespace_def();
        let mut world = spawn_test_world([ndef].span());
        world.sync_perms_and_inits(contract_defs());

        let (contract_address, _) = world.dns(@"actions").unwrap();
        let actions_system = IActionsDispatcher { contract_address };

        // Spawn the player at position (10, 10)
        actions_system.spawn();
        let initial_moves: Moves = world.read_model(caller);
        let initial_position: Position = world.read_model(caller);

        assert(
            initial_position.vec.x == 10 && initial_position.vec.y == 10, 'wrong initial position',
        );

        // Move to position (25, 30)
        let target_position = Vec2 { x: 25, y: 30 };
        actions_system.move_to(target_position);

        // Check that the player's position has been updated
        let new_position: Position = world.read_model(caller);
        assert(new_position.vec.x == target_position.x, 'position x is wrong');
        assert(new_position.vec.y == target_position.y, 'position y is wrong');

        // Check that the player's moves count has been decremented
        let moves: Moves = world.read_model(caller);
        assert(moves.remaining == initial_moves.remaining, 'moves should not change');

        // Test moving to another position
        let target_position2 = Vec2 { x: 15, y: 40 };
        actions_system.move_to(target_position2);

        // Check that the player's position has been updated
        let final_position: Position = world.read_model(caller);
        assert(final_position.vec.x == target_position2.x, 'position x is wrong');
        assert(final_position.vec.y == target_position2.y, 'position y is wrong');

        // Check that the player's moves count has been decremented again
        let final_moves: Moves = world.read_model(caller);
        assert(final_moves.remaining == moves.remaining, 'moves should not change');
    }
}
