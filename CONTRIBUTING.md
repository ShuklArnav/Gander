# Contributing to Gander

Contributions are welcome. Keep changes focused and follow the
existing Goose idioms used throughout the repository.

## Development setup

Gander is a small CLI library for the [Goose](https://github.com/aardappel/goose)
programming language. It builds a command tree from Goose enums and dispatches
matching `exec` overloads for the root command and selected subcommands.

### Specific Changes

- **src/parser.h**

  1. Replace line 1900 by

      ```cpp
        if (cf->source == ES_FIELDS) {
            // fields<T> takes the name and accessor, and optionally the read type.
            if (cf->names.size() != 2 && cf->names.size() != 3)
                Error("fields requires 2 or 3 binding(s)");
        } else {
            auto arity = cf->source == ES_VARIANTS ? 2u : 1u;
      ```

  2. Hence, add after line 1907

      ```cpp
        }
      ```

- **src/typecheck_expansion.h**

  1. Replace lines 326 to 327 by

      ```cpp
            const vector<Field> *fields;
            const vector<TypeExpr *> *ftypes;
            if (t->kind == TY_VARIANT) {
                auto inst = GetEnumInst(t->var->adt);
                auto vi = inst->en->VariantIndex(t->var->variant);
                fields = &t->var->variant->fields;
                ftypes = &inst->vftypes[vi];
            } else {
                auto inst = GetStructInst(t);
                fields = &inst->st->fields;
                ftypes = &inst->ftypes;
            }
            for (size_t i = 0; i < fields->size(); i++) {
                auto &f = (*fields)[i];
      ```

  2. Hence add after 342

      ```cpp
                if (cf->names.size() == 3) {
                    // The read type: what `value.A` has as an expression, so a
                    // varint field is i64 and a relative reference is plain.
                    entries.back().push_back({
                        cf->bindings[2],
                        nullptr,
                        LoadType((*ftypes)[i])
                    });
                }
      ```

Gander requires the `fields<T>` expansion to accept both of these forms:

```goose
const for <NAME, ACCESSOR> in fields<MyStruct> {}
const for <NAME, ACCESSOR, READ_TYPE> in fields<MyStruct> {}
```

The optional third binding receives the field's read type, including enum
variant fields. Do not replace it with an assumed struct-only or storage-type
implementation.

## Checks

Typecheck and run the integration example:

```powershell
goose check test/test.goose
goose test/test.goose
```

For overflow, range, and tag checks, use:

```powershell
goose test/test.goose --debug
```

When changing `src/cli.goose`, always run both typechecking and execution
for `test/test.goose`. Keep the example's output comments accurate.

To format changed Goose files:

```powershell
goose format test/test.goose
goose format src/cli.goose
goose format src/init.goose
goose format gander.goose
```

## Code conventions

- Public API names belong in the `gander` namespace.
- Enum variant types used by callers remain in the caller's import scope.
- Preserve relative references and pool ownership for `Command` and `Option` storage.
- Use `const for` and `const if` for compile-time enum and field specialization.
- Use `recursive fn` for recursion or nested enum specialization.
- Follow Goose statement-ending rules; block constructs do not need trailing semicolons.
- Use `const u8[:]` for immutable strings and `u8[>..]` for assembled output buffers.

## Pull requests

Before opening a pull request:

1. Describe the user-visible behavior and implementation changes.
2. Add or update the focused example if dispatch or command construction changes.
3. Run the checks above.
4. Call out syntax or API changes clearly.

Do not include build artifacts or unrelated formatting changes.