```pony
class iso BenchMaybe is MicroBenchmark
  fun name(): String => "Maybe"

  fun apply() =>
    let x: (U64 | None) = @rand[I32]().u64()
    DoNotOptimise[U64](
      Opt.get[U64](Opt.map[U64, U64](x, {(n) => n * 2 }), 0))
    DoNotOptimise.observe()

class iso BenchIter is MicroBenchmark
  fun name(): String => "Iter"

  fun apply() ? =>
    let x: (U64 | None) = @rand[I32]().u64()
    DoNotOptimise[U64](
      Iter[U64].maybe(x).map[U64]({(n) => n * 2 }).next()?)
    DoNotOptimise.observe()
```

# Optimized IR

`corral run -- ponyc -r ir --extfun`
```llvm
define fastcc nonnull %112* @BenchMaybe_ref_apply_o(%168* nocapture readnone dereferenceable(8)) unnamed_addr !pony.abi !2 {
  %2 = alloca [32 x i8], align 8
  %3 = tail call i32 (...) @rand()
  br i1 icmp eq (%57* bitcast (%39* @36 to %57*), %57* @54), label %11, label %4

4:                                                ; preds = %1
  %5 = sext i32 %3 to i64
  %6 = shl nsw i64 %5, 1
  %7 = bitcast [32 x i8]* %2 to %39**
  store %39* @36, %39** %7, align 8
  %8 = getelementptr inbounds [32 x i8], [32 x i8]* %2, i64 0, i64 8
  %9 = bitcast i8* %8 to i64*
  store i64 %6, i64* %9, align 8
  %10 = bitcast [32 x i8]* %2 to %1*
  br label %11

11:                                               ; preds = %1, %4
  %12 = phi %1* [ %10, %4 ], [ bitcast (%112* @110 to %1*), %1 ]
  %13 = getelementptr inbounds %1, %1* %12, i64 0, i32 0
  %14 = load %2*, %2** %13, align 8
  %15 = icmp eq %2* %14, bitcast (%57* @54 to %2*)
  br i1 %15, label %20, label %16

16:                                               ; preds = %11
  %17 = getelementptr inbounds %1, %1* %12, i64 1
  %18 = bitcast %1* %17 to i64*
  %19 = load i64, i64* %18, align 8
  br label %20

20:                                               ; preds = %11, %16
  %21 = phi i64 [ %19, %16 ], [ 0, %11 ]
  tail call void asm sideeffect "", "imr,~{memory}"(i64 %21) #1
  tail call void asm sideeffect "", "~{memory}"() #1
  ret %112* @110
}
```

```llvm
define fastcc nonnull %112* @BenchIter_ref_apply_o(%152* nocapture readnone dereferenceable(8)) unnamed_addr !pony.abi !2 {
  %2 = tail call i32 (...) @rand()
  %3 = sext i32 %2 to i64
  %4 = shl nsw i64 %3, 1
  tail call void asm sideeffect "", "imr,~{memory}"(i64 %4) #1
  tail call void asm sideeffect "", "~{memory}"() #1
  ret %112* @110
}
```

# Microbenchmark

`corral run -- ponyc -V1 --extfun && ./maybe-perf`
```
Benchmark results will have their mean and median adjusted for overhead.
You may disable this with --noadjust.

Benchmark                                   mean            median   deviation  iterations
Maybe                                      54 ns             54 ns      ±1.53%     2000000
Iter                                       55 ns             54 ns      ±2.46%     2000000
```
