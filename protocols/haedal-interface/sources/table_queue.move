
#[allow(unused_variable, unused_use, unused_function, unused_field)]
module haedal::table_queue {

    use sui::table::{Self, Table};
    use sui::tx_context::TxContext;

    struct TableQueue<phantom Element: store> has store {
        head: u64,
        tail: u64,
        contents: Table<u64, Element>,
    }

    const EIndexOutOfBound: u64 = 0;
    const ETableNonEmpty: u64 = 1;

    public fun empty<Element: store>(ctx: &mut TxContext): TableQueue<Element> {
        abort 0
    }

    public fun length<Element: store>(t: &TableQueue<Element>): u64 {
        abort 0
    }

    public fun is_empty<Element: store>(t: &TableQueue<Element>): bool {
        abort 0
    }

    public fun push_back<Element: store>(t: &mut TableQueue<Element>, e: Element) {
        abort 0
    }

    public fun borrow_front<Element: store>(t: &TableQueue<Element>): &Element {
        abort 0
    }

    public fun borrow_front_mut<Element: store>(t: &mut TableQueue<Element>): &mut Element {
        abort 0
    }

    public fun pop_front<Element: store>(t: &mut TableQueue<Element>): Element {
        abort 0
    }

    public fun destroy_empty<Element: store>(t: TableQueue<Element>) {
        abort 0
    }

    public fun head<Element: store>(t: &TableQueue<Element>): u64 {
        abort 0
    }
    
    public fun tail<Element: store>(t: &TableQueue<Element>): u64 {
        abort 0
    }

    public fun borrow<Element: store>(t: &TableQueue<Element>, k: u64): &Element {
        abort 0
    }

    public fun borrow_mut<Element: store>(t: &mut TableQueue<Element>, k: u64): &mut Element {
        abort 0
    }
}
