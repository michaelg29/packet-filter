#include <stdio.h>
#include <string.h>

typedef struct {
  char valid;
  char last;
  char dest;
} axis_input;

typedef struct {
  axis_input ingress[4];
} switch_input;

typedef struct {
  char grant[4];
  char select;
} switch_output;

int cur_grant[4];
int next_rr[4];

int waiting[4];
int errors = 0;

void reset_state() {
  for (int i = 0; i < 4; i++) {
    cur_grant[i] = -1;
    next_rr[i] = 0;
  }
}

switch_output arbitrate(switch_input input, int egress, int cycle) {
  switch_output output;
  memset(&output, 0, sizeof(output));
  output.select = -1;

  if (cur_grant[egress] != -1) {
    int locked = cur_grant[egress];
    axis_input pkt = input.ingress[locked];

    if (pkt.valid && pkt.dest == egress) {
      output.grant[locked] = 1;
      output.select = locked;

      if (pkt.last) {
        cur_grant[egress] = -1;
        next_rr[egress] = (locked + 1) % 4;
        printf("Cycle %d, Egress %d: Frame ended at ingress %d. RR now %d.\n",
               cycle, egress, locked, next_rr[egress]);
      }
      return output;
    } else {
      printf("Cycle %d, Egress %d: Unexpected loss of lock at ingress %d.\n",
             cycle, egress, locked);
      cur_grant[egress] = -1;
      next_rr[egress] = (locked + 1) % 4;
    }
  }

  for (int i = 0; i < 4; i++) {
    int idx = (next_rr[egress] + i) % 4;
    axis_input pkt = input.ingress[idx];

    if (pkt.valid && pkt.dest == egress) {
      cur_grant[egress] = idx;
      output.grant[idx] = 1;
      output.select = idx;

      printf("Cycle %d, Egress %d: Locking onto ingress %d.\n", cycle, egress, idx);

      if (pkt.last) {
        cur_grant[egress] = -1;
        next_rr[egress] = (idx + 1) % 4;
        printf("Cycle %d, Egress %d: Immediate frame end at ingress %d. RR now %d.\n",
               cycle, egress, idx, next_rr[egress]);
      }
      break;
    }
  }

  if (output.select == -1) output.select = 0;
  return output;
}

void collect_stats(switch_input input, switch_output output, int egress, int cycle) {
  for (int i = 0; i < 4; i++) {
    if (input.ingress[i].valid && input.ingress[i].dest == egress && !output.grant[i]) {
      waiting[i]++;
      printf("Cycle %d: Ingress %d valid but waiting for egress %d (waiting total: %d)\n",
             cycle, i, egress, waiting[i]);
    }
  }
}

int main() {
  reset_state();

  switch_input inputs[5] = {
    {{{1,0,0},{1,0,0},{0,0,0},{1,1,2}}},
    {{{1,1,0},{1,1,0},{1,0,1},{0,0,0}}},
    {{{0,0,0},{0,0,0},{1,0,1},{0,0,0}}},
    {{{0,0,0},{0,0,0},{1,0,1},{0,0,0}}},
    {{{0,0,0},{0,0,0},{1,1,1},{0,0,0}}}
  };

  for (int cycle = 0; cycle < 5; cycle++) {
    printf("\n========== Cycle %d ==========\n", cycle);

    for (int ingress=0; ingress<4; ingress++){
      axis_input pkt = inputs[cycle].ingress[ingress];
      if(pkt.valid)
        printf("Ingress %d: valid=1, last=%d, dest=%d\n", ingress, pkt.last, pkt.dest);
    }

    for (int egress = 0; egress < 4; egress++) {
      switch_output out = arbitrate(inputs[cycle], egress, cycle);
      collect_stats(inputs[cycle], out, egress, cycle);

      printf("Cycle %d, Egress %d selects ingress %d | grants: [%d %d %d %d]\n",
             cycle, egress, out.select, out.grant[0], out.grant[1], out.grant[2], out.grant[3]);
    }
  }

  printf("\nFinal Waiting counts per ingress: [%d %d %d %d]\n", waiting[0], waiting[1], waiting[2], waiting[3]);
  printf("Total errors detected: %d\n", errors);

  return 0;
}
