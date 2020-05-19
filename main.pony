use "maybe"
use "ponybench"

actor Main is BenchmarkList
  new create(env: Env) =>
    PonyBench(env, this)

  fun tag benchmarks(bench: PonyBench) =>
    bench(BenchMaybe)
    bench(BenchIter)

class iso BenchMaybe is MicroBenchmark
  fun name(): String => "Maybe"

  fun apply() =>
    let x: (U64 | None) = @rand[I32]().u64()
    DoNotOptimise[U64](
      Opt.get[U64](Opt.map[U64, U64](x, {(n) => n * 2 }), 0))
    DoNotOptimise.observe()

class iso BenchIter is MicroBenchmark
  fun name(): String => "Iter"

  fun apply() =>
    let x: (U64 | None) = @rand[I32]().u64()
    DoNotOptimise[U64](
      Iter[U64].maybe(x).map[U64]({(n) => n * 2 }).get_or(0))
    DoNotOptimise.observe()

class Iter[A] is Iterator[A]
  let _iter: Iterator[A]

  new create(iter: Iterator[A]) =>
    _iter = iter

  new maybe(value: (A | None)) =>
    _iter =
      object is Iterator[A]
        var _value: (A | None) = consume value
        fun has_next(): Bool => _value isnt None
        fun ref next(): A ? => (_value = None) as A
      end

  fun ref has_next(): Bool =>
    _iter.has_next()

  fun ref next(): A ? =>
    _iter.next()?

  fun ref get_or(default: A): A =>
    if _iter.has_next() then
      try _iter.next()? else default end
    else
      default
    end

  fun ref map[B](f: {(A!): B ?} box): Iter[B]^ =>
    Iter[B](
      object is Iterator[B]
        let _iter: Iterator[A] = _iter
        let _f: {(A!): B ?} box = f
        fun ref has_next(): Bool => _iter.has_next()
        fun ref next(): B ? => _f(_iter.next()?)?
      end)
