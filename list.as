// Modified from arrow list test
import libc from "./lib/libc";

struct List {
  _capacity: uint64,
  _size: uint64,
  _elements: *mutable *mutable byte
}

// Make a new list
def list_new() -> List {
  return List(
    0,
    0,
    0 as *mutable *mutable byte
  );
}

// Free up memory used by list
def list_destroy(l: List) {
  libc.free(l._elements);
}

// Get value at index
def list_at(mutable self: List, index: uint64) -> *byte {
  return *(self._elements + index);
}

// Set value at index
def list_set(mutable self: List, index: uint64, val: *byte) {
  *(self._elements + index) = val;
}

// Reserve space
def list_reserve(mutable self: List, capacity: uint64) {
  // We'll use 3/2 as the size to grow
  let mutable new_cap: uint64 = self._capacity;
  if self._capacity < capacity {
    if self._capacity > 1 {
      new_cap = (self._capacity * 3) / 2;
    } else {
      new_cap = 2;
    }
    self._elements = libc.realloc(
      self._elements as *mutable byte,
      new_cap as int64) as *mutable *mutable byte;
  } else {
    if capacity < ((self._capacity * 2) / 3) {
      if self._size > 1 {
        new_cap = (self._size * 3) / 2;
      } else {
        new_cap = 2;
      }
      self._elements = libc.realloc(
        self._elements as *mutable byte,
        new_cap as int64) as *mutable *mutable byte;
    }
  }
  self._capacity = new_cap;
}

// Make a (shallow) copy of the list
def list_copy(self: List) -> mutable List {
  let mutable l = list_new();

  list_reserve(l, self._size);
  libc.memmove(l._elements, self._elements, self._size);
  l._size = self._size;
  return l;
}

// Add value to end of list
def list_push(mutable self: List, value: *byte) {
  // Reserve additional space (if needed)
  list_reserve(self, self._size + 1);

  // Insert the value at the next available index
  let i: *mutable *mutable byte = (self._elements + self._size);
  *i = value;

  // Increase our size
  self._size += 1;
}

// Add one list to the end of another
def list_concat(mutable self: List, value: List) {
  list_reserve(self, self._size + value._size);
  libc.memmove(
    self._elements + self._size,
    value._elements,
    value._size);
  self._size += value._size;
}

// Get the length of the list
def list_length(self: List) -> uint64 {
  return self._size;
}

// Get value from end of list
// Note: This removes the value from the list as well
// To get this value without removing it, do
// list_get(list, list_length(list) - 1);
def list_pop(mutable self: List) -> *byte {
  let ret: *byte = *(self._elements + (self._size -= 1));
  list_reserve(self, self._size);
  return ret;
}

// Inserts a value into the list at the specified index
def list_insert(mutable self: List, value: *byte, index: uint64) {
  list_reserve(self, self._size + 1);
  libc.memmove(self._elements + index + 1, self._elements + index, self._size - index);
  *(self._elements + index) = value;
  self._size += 1;
}

// Inserts values from a list into the list starting at the specified index
def list_insert_list(mutable self: List, value: List, index: uint64) {
  list_reserve(self, self._size + value._size);
  libc.memmove(
    self._elements + index + value._size,
    self._elements + index,
    self._size - index);
  libc.memmove(
    self._elements + index,
    value._elements,
    value._size);
  self._size += value._size;
}

// Removes a value from the list at the specified index
def list_remove(mutable self: List, index: uint64) {
  libc.memmove(
    self._elements + index,
    self._elements + index + 1,
    self._size - index);
  self._size -= 1;
  list_reserve(self, self._size);
}

// Removes all values from the list for which the compare function returns 0
def list_remove_all(mutable self: List, val: *byte, compare: (*byte, *byte) -> int64) {
  let mutable index: int64 = list_search(self, val, compare);
  while index >= 0 {
    list_remove(self, index);
    index = list_search(self, val, compare);
  }
}

// Gets a slice of the list starting from start and ending at (but not including) end
// Negative indices start from end of list
def list_slice(mutable self: List, start: int64, end: int64) -> mutable List {
  let mutable real_start: uint64;
  let mutable real_end: uint64;
  let mutable l: List = list_new();
  if start < 0 {
    real_start = self._size - start;
    if real_start < 0 {
      return l; // Slice is outside of our list
    }
  } else {
    real_start = start;
    if real_start >= self._size {
      return l; // Slice is outside of our list
    }
  }
  if end < 0 {
    real_end = self._size - end;
    if real_end < 0 {
      return l; // Slice is outside of our list
    }
  } else {
    real_end = end;
    if real_end >= self._size {
      return l; // Slice is outside of our list
    }
  }
  if real_end < real_start {
    let temp = real_end;
    real_end = real_start;
    real_start = temp;
  }
  let n = (real_end - real_start) + 1;
  list_reserve(l, n);
  libc.memmove(
    l._elements,
    self._elements + real_start,
    n);
  l._size = n;
  return l;
}

// Helper function for list_reverse
def list_swap_recursive(mutable self: List, i1: uint64, i2: uint64) {
  if i1 >= i2 {
    return;
  }
  let temp = *(self._elements + i1);
  *(self._elements + i1) = *(self._elements + i2);
  *(self._elements + i2) = temp;

  list_swap_recursive(self, i1 + 1, i2 - 1);
}

// Reverses the order of all elements in the list
def list_reverse(mutable self: List) {
  list_swap_recursive(self, 0, self._size - 1);
}

// Sorts the list using the compare function to determine order
// compare should return positive for greater than, zero for equal, and negative
// for less than
def list_sort(mutable self: List, compare: (*byte, *byte) -> int64) {
  // TODO: Verify that this size calculation is correct
  let element_size = (((0 as *byte) + 1) as *byte - (0 as *byte)) as int64;
  libc.qsort(
    self._elements,
    self._size as int64,
    element_size,
    compare);
}

// Search through a sorted list using the specified compare function
// Note: DO NOT use this function on an unsorted list
// doing so is undefined behavior and could go on forever
// Binary search, best for sorted list
def list_bsearch(mutable self: List, key: *byte, compare: (*byte, *byte) -> int64) -> int64{
  // TODO: Verify that this size calculation is correct
  let element_size = (((0 as *byte) + 1) as *byte - (0 as *byte)) as int64;
  let ptr = libc.bsearch(
    key,
    self._elements,
    self._size as int64,
    element_size,
    compare);
    return (ptr - self._elements) as int64;
}

// Search through a list using the specified compare function
// Linear search, best for unsorted list
def list_search(mutable self: List, key: *byte, compare: (*byte, *byte) -> int64) -> int64{
  let mutable i: uint64 = 0;
  while i < self._size {
    if compare(key, *(self._elements + i)) == 0 {
      return i as int64;
    }
    i += 1;
  }
  return -1;
}

// Run all values in the list through m and return a list of the results
def list_map(self: List, m: (*byte) -> *byte) -> mutable List{
  let mutable l = list_new();
  list_reserve(l, self._size);
  let mutable i: uint64 = 0;
  while i < self._size {
    *(l._elements + i) = m(*(self._elements + i));
    i += 1;
  }
  l._size = self._size;
}

// Run all values in the list through m and replace them with the results
def list_map_mutable(mutable self: List, m: (*byte) -> *byte) {
  let mutable i: uint64 = 0;
  while i < self._size {
    *(self._elements + i) = m(*(self._elements + i));
    i += 1;
  }
}

// Return a list of all values for which f(val) is true
def list_filter(self: List, f: (*byte) -> bool) -> mutable List {
  let mutable l = list_new();
  let mutable i: uint64 = 0;
  while i < self._size {
    if f(*(self._elements + i)) {
      list_push(l, *(self._elements + i));
    }
    i += 1;
  }
  return l;
}

// Run all values in the list through f and only keep those for which f(val) is true
def list_filter_mutable(mutable self: List, f: (*byte) -> bool) {
  let mutable i: uint64 = 0;
  while i < self._size {
    if f(*(self._elements + i)) == false {
      list_remove(self, i);
    }
    i += 1;
  }
}

// Returns a list of unique elements
def list_unique(self: List, compare: (*byte, *byte) -> int64) -> mutable List {
  let mutable l = list_new();
  let mutable i: uint64 = 0;
  let mutable index: int64 = -1;
  while i < self._size {
    index = list_search(self, *(self._elements + i), compare);
    if index == i {
      list_push(l, *(self._elements + i));
    }
    i += 1;
  }
  return l;
}

// Removes all duplicate elements from the list
def list_unique_mutable(self: List, compare: (*byte, *byte) -> int64) {
  let mutable i: uint64 = 0;
  let mutable index: int64 = -1;
  while i < self._size {
    index = list_search(self, *(self._elements + i), compare);
    if index != i {
      list_remove(l, i);
    }
    i += 1;
  }
}

def main() -> int {
  let mutable l = list_new();
  return 0;
}
