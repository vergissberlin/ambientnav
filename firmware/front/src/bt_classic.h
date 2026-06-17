#pragma once
#include <stdbool.h>

void btClassicInit();
void taskBTClient(void* param);
bool sppSend(const char* json);
