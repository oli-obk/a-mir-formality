#![allow(non_snake_case)]

#[test]
fn holds() {
    crate::assert_ok!(
        //@check-pass
        [
            crate Foo {
                trait Foo {}

                impl<do E> Foo for u32 where <u32 as Foo> Const E {}
            }
        ]

        expect_test::expect!["()"]
    )
}
