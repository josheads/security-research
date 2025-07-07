/*
 * Copyright 2025 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#ifndef __COMPAT_H
#define __COMPAT_H

#include <string.h>
#include <stdlib.h>
#include <alloca.h>

#if defined(__APPLE__)
#define program_invocation_short_name getprogname()
#define strdupa(s) strcpy(alloca(strlen(s) + 1), s)
#define strchrnul(s, c) ({ char *_s = strchr(s, c); if (!_s) _s = s + strlen(s); _s; })
#endif

#if !defined(__GLIBC__)
static inline void *mempcpy(void *dest, const void *src, size_t n)
{
    return (char *)memcpy(dest, src, n) + n;
}
#endif

#ifdef __GLIBC__
# if __GLIBC_MINOR__ < 38
#  pragma GCC diagnostic ignored "-Wstringop-overflow"
#  define strlcpy(d, s, n) strncpy((d), (s), (n))
#  define strlcat(d, s, n) strncat((d), (s), (n))
# endif
#endif


#endif
