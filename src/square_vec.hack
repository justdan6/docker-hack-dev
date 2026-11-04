use namespace HH\Lib\Vec;

function square_vec(vec<num> $values): vec<num> {
  return Vec\map($values, $value ==> $value * $value);
}
