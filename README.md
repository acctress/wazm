# wazm
A WebAssembly interpreter, decodes .wasm binaries and executes them on a stack based virtual machine.

As of `27/02/2026`, wazm can decode LEB128 and parse `.wasm` files with basic structure. For example:
Take the `.wat` file:
```wat
(module
    (func (param i32 i64) (result f32)
        f32.const 0
    )

    (func (param f64) (result i32 i32)
        i32.const 0
        i32.const 0
    )
)
```

Two functions are defined in the module, the first function is defined with two parameters of the types `i32` and `i64`, with one result type `f32`, a constant `f32 0` is returned from the function.

With `wat2wasm`, `.wat` files can be compiled to `.wasm` binaries, with this wazm can decode this program.

```
module has 2 types
type func has 2 parameter(s)
type func has 1 result(s)
type func has 1 parameter(s)
type func has 2 result(s)
```