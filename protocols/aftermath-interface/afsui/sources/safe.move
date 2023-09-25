#[allow(unused_field)]
module afsui::safe{
    use sui::object::{UID, ID};
    use std::option::Option;
    
    struct Safe<T> has key {
        id: UID,
        owner_cap_id: ID,
        authorized_object_id: Option<ID>,
        obj: T
    }
}