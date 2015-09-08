import list from "./list"

struct Set {
  _values: mutable list.List,
  _comparator: (*byte, *byte) -> int64
}

// Create a new Set
def set_new(compare: (*byte, *byte) -> int64) -> mutable Set {
  return Set(
    list_new(),
    compare
  );
}

// Free any memory used by the set
def set_destroy(mutable self: Set) {
  list_destroy(self._values)
}

// Create a set from a list
// The compare param is used to determine equality of values
// So that the set can purge duplicate values
def set_from_list(l: List, compare: (*byte, *byte) -> int64) -> mutable Set {
  let mutable s = set_new(compare);
  s._values = list_unique(l, compare);
  return s;
}

// Create a list from a set
def list_from_set(self: Set) -> mutable List {
  return list_copy(self._values);
}

// Create a set that uses the specified list internally
// Any modifications to the set also modify the list
// Note that this is somewhat dangerous because
// this function will eliminate duplicate values from
// the list while creating the set, and it is possible
// to introduce duplicate values that the set would be
// unaware of by modifying the list.
def list_as_set(l: List, compare: (*byte, *byte) -> int64) -> mutable Set {
  let mutable s = set_new();
  s._values = l;
  list_unique_mutable(s._values, compare);
  s._compare = compare;
  return s;
}

// Returns the set's internal list
// Any modifications to the list also modify the set
// Note that this is somewhat dangerous since it can
// introduce duplicate values that the set would be
// unaware of.
def set_as_list(s: Set) -> mutable List {
  return s._values;
}

// Insert a value into the set
// Does nothing if the value already exists in this set
def set_insert(mutable self: Set, val: *byte) {
  if list_search(self, val, self._comparator) < 0 {
    list_push(self._values, val);
  }
}

// Removes a value from the set
def set_remove(mutable self: Set, val *byte) {
  list_remove_all(self, val, self._comparator);
}

// Returns the union of sets a and b
def set_union(a: Set, b: Set) -> mutable Set {
  let mutable s = set_new();
  s._values = list_copy(b._values);
  let mutable i: uint64 = 0;
  while i < list_length(a._values) {
    set_insert(s, list_at(a, i));
    i += 1;
  }
  return s;
}

// Returns the intersection of sets a and b
def set_intersection(a: Set, b: Set) -> mutable Set {
  let mutable s = set_new();
  let mutable size: uint64;
  let mutable i: uint64 = 0;
  let mutable temp: *byte;
  let mutable l_s: Set; // Largest set
  let mutable s_s: Set; // Smallest set
  if list_length(a._values) > list_length(b._values) {
    size = list_length(a._values);
    l_s = a;
    s_s = b;
  } else {
    size = list_length(b._values);
    l_s = b;
    s_s = a;
  }
  while i < size {
    temp = list_at(l_s, i);
    if list_search(s_s._values, temp, s_s._comparator) >= 0 {
      set_insert(s, temp);
    }
    i += 1;
  }
  return s;
}

// Set difference, a - b
def set_subtract(a: Set, b: Set) -> mutable Set {
  let mutable s = set_new();
  s._values = list_copy(a._values);
  let mutable i: int64 = 0;
  while i < list_length(b._values) {
    list_remove_all(s, list_at(b, i));
    i += 1
  }
  return s;
}

// Symmetric difference between sets a and b
def set_difference(a: Set, b: Set) -> mutable Set {
  let left = set_subtract(a, b);
  let right = set_subtract(b, a);
  return set_union(left, right);
}
