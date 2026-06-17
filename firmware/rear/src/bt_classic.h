#pragma once
#include <stdbool.h>

void btClassicServerInit();
void taskBTServer(void* param);
bool sppSend(const char* json);
