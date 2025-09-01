use starknet::{ContractAddress};

#[derive(Copy, Drop, Serde, Debug)]
#[dojo::model]
pub struct Moves {
    #[key]
    pub player: ContractAddress,
    pub remaining: u8,
    pub last_direction: Direction,
    pub can_move: bool,
}

#[derive(Drop, Serde, Debug)]
#[dojo::model]
pub struct DirectionsAvailable {
    #[key]
    pub player: ContractAddress,
    pub directions: Array<Direction>,
}

#[derive(Copy, Drop, Serde, IntrospectPacked, Debug)]
#[dojo::model]
pub struct Position {
    #[key]
    pub player: ContractAddress,
    pub vec: Vec2,
}

#[derive(Copy, Drop, Serde, IntrospectPacked, Debug)]
#[dojo::model]
pub struct PositionSigned {
    #[key]
    pub player: ContractAddress,
    pub vec: Vec2Signed,
}

#[derive(Copy, Drop, Serde, Debug)]
#[dojo::model]
pub struct PositionCount {
    #[key]
    pub identity: ContractAddress,
    pub position: Span<(u8, u128)>,
}


#[derive(Serde, Copy, Drop, Introspect, DojoStore, PartialEq, Debug, Default)]
pub enum Direction {
    #[default]
    None,
    Left,
    Right,
    Up,
    Down,
}


#[derive(Copy, Drop, Serde, IntrospectPacked, DojoStore, Debug)]
pub struct Vec2 {
    pub x: u32,
    pub y: u32,
}

#[derive(Copy, Drop, Serde, IntrospectPacked, DojoStore, Debug)]
pub struct Vec2Signed {
    pub x: i32,
    pub y: i32,
}

#[derive(Copy, Drop, Serde, IntrospectPacked, DojoStore, Debug)]
pub struct Vec3 {
    pub x: i128,
    pub y: i128,
    pub z: i128,
}

impl DirectionIntoFelt252 of Into<Direction, felt252> {
    fn into(self: Direction) -> felt252 {
        match self {
            Direction::None => 0,
            Direction::Left => 1,
            Direction::Right => 2,
            Direction::Up => 3,
            Direction::Down => 4,
        }
    }
}

impl OptionDirectionIntoFelt252 of Into<Option<Direction>, felt252> {
    fn into(self: Option<Direction>) -> felt252 {
        match self {
            Option::None => 0,
            Option::Some(d) => d.into(),
        }
    }
}

pub impl U32IntoI32 of Into<u32, i32> {
    fn into(self: u32) -> i32 {
        self.try_into().unwrap()
    }
}

#[generate_trait]
impl Vec2Impl of Vec2Trait {
    fn is_zero(self: Vec2) -> bool {
        if self.x - self.y == 0 {
            return true;
        }
        false
    }

    fn is_equal(self: Vec2, b: Vec2) -> bool {
        self.x == b.x && self.y == b.y
    }
}

#[generate_trait]
impl Vec2SignedImpl of Vec2SignedTrait {
    fn is_zero(self: Vec2Signed) -> bool {
        if self.x == 0 && self.y == 0 {
            return true;
        }
        false
    }

    fn is_equal(self: Vec2Signed, b: Vec2Signed) -> bool {
        self.x == b.x && self.y == b.y
    }
}

#[generate_trait]
impl Vec3Impl of Vec3Trait {
    fn is_zero(self: Vec3) -> bool {
        if self.x == 0 && self.y == 0 && self.z == 0 {
            return true;
        }
        false
    }

    fn is_equal(self: Vec2Signed, b: Vec2Signed) -> bool {
        self.x == b.x && self.y == b.y
    }
}

#[cfg(test)]
mod tests {
    use super::{Vec2, Vec2Trait, Vec2Signed, Vec2SignedTrait};

    #[test]
    fn test_vec_is_zero() {
        assert(Vec2Trait::is_zero(Vec2 { x: 0, y: 0 }), 'not zero');
    }

    #[test]
    fn test_vec_is_equal() {
        let position = Vec2 { x: 420, y: 0 };
        assert(position.is_equal(Vec2 { x: 420, y: 0 }), 'not equal');
    }

    #[test]
    fn test_vec_signed_is_zero() {
        assert(Vec2SignedTrait::is_zero(Vec2Signed { x: 0, y: 0 }), 'not zero');
    }

    #[test]
    fn test_vec_signed_is_equal() {
        let position = Vec2Signed { x: -420, y: 0 };
        assert(position.is_equal(Vec2Signed { x: -420, y: 0 }), 'not equal');
    }

    #[test]
    fn test_vec_is_zero() {
        assert(Vec3Trait::is_zero(Vec3 { x: 0, y: 0 , z: 0}), 'not zero');
    }

    #[test]
    fn test_vec_is_equal() {
        let position = Vec3 { x: 420, y: 0 , z: -420};
        assert(position.is_equal(Vec2 { x: 420, y: 0 , z: -420}), 'not equal');
    }
}
