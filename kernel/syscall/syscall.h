#pragma once

#include <trap/traps.h>

void SolveSystemCall(TrapFrame *tf);
int SystemCall(int num, ...);