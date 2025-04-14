
typedef struct {
  char valid;
  char last;
  char dest;
} axis_input;

typedef struct {
  axis_input ingress[4];
} switch_input;

typedef struct {
  char grant[4]; // grant signal to each ingress port
  char select; // select signal to multiplexer
} switch_output;

// global state variables
int cur_grant[4];
int next_rr[4]; // next scheduled ingress for each egress port

switch_output arbitrate(switch_input input) {
  // simulate RR for each egress
  for (int i = 0; i < 4; i++) {
    if (cur_grant[i] && input.ingress[i].valid) {

      if (input.ingress[i].last) {
        // update RR

      }
    }
  }
}

// global monitor variables
int waiting[4];
int errors;

void collect_stats(switch_input input, switch_output output) {
  // verify correspondance between grant and selection
  for (int i = 0; i < 4; i++) {
    if (i == output.select && !grant[i]) {
      errors++;
    }
    if (i != output.select && grant[i]) {
      errors++;
    }
  }

  // allocate wait times based on valid signal
  for (int i = 0; i < 4; i++) {
    if (input.ingress[i].valid && !output.grant[i]) {
      waiting[i]++;
    }
  }
}

int main() {
  input.ingress[0].valid = 1;
  collect_stats(input0, arbitrate(input0)); // CC0
  collect_stats(input1, arbitrate(input1)); // CC1
  collect_stats(input2, arbitrate(input2)); // CC2
  collect_stats(input3, arbitrate(input3)); // CC3
  collect_stats(input4, arbitrate(input4)); // CC4
  collect_stats(input5, arbitrate(input5)); // CC5

}
