/* language.c -- Natural language handlinng routines
 *
 * Copyright (c) 1994-2016 Carnegie Mellon University.  All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in
 *    the documentation and/or other materials provided with the
 *    distribution.
 *
 * 3. The name "Carnegie Mellon University" must not be used to
 *    endorse or promote products derived from this software without
 *    prior written permission. For permission or any legal
 *    details, please contact
 *      Carnegie Mellon University
 *      Center for Technology Transfer and Enterprise Creation
 *      4615 Forbes Avenue
 *      Suite 302
 *      Pittsburgh, PA  15213
 *      (412) 268-7393, fax: (412) 268-7395
 *      innovation@andrew.cmu.edu
 *
 * 4. Redistributions of any form whatsoever must retain the following
 *    acknowledgment:
 *    "This product includes software developed by Computing Services
 *     at Carnegie Mellon University (http://www.cmu.edu/computing/)."
 *
 * CARNEGIE MELLON UNIVERSITY DISCLAIMS ALL WARRANTIES WITH REGARD TO
 * THIS SOFTWARE, INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS, IN NO EVENT SHALL CARNEGIE MELLON UNIVERSITY BE LIABLE
 * FOR ANY SPECIAL, INDIRECT OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN
 * AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING
 * OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 */

#include "language.h"

#include <config.h>
#include <string.h>
#include <syslog.h>

#include "libconfig.h"
#include "xmalloc.h"

#ifdef ENABLE_LIBTEXTCAT

#include "libtextcat/textcat.h"

static void *textcats = NULL;

void language_init(void)
{
    static int init = 0;

    if (!init) {
        char *conf = (char *) config_getstring(IMAPOPT_LANGUAGE_CONF_FILE);
        if (!conf)
            conf = strconcat(config_dir, "/languages/conf.txt", (char*)NULL);
        else
            conf = xstrdup(conf);

        char *modpath = (char *) config_getstring(IMAPOPT_LANGUAGE_MODEL_PATH);
        if (!modpath)
            modpath = strconcat(config_dir, "/languages/", (char*)NULL);
        else
            modpath = xstrdup(modpath);

        textcats = special_textcat_Init(conf, modpath);
        if (textcats == NULL) {
            syslog(LOG_ERR, "Failed to initialize languages (conf=%s, models=%s)",
                    conf, modpath);
            exit(1);
        }
        free(conf);
        free(modpath);
        init = 1;
    }
}

EXPORTED char *language_detect(const char *src, size_t len)
{
    char *lang, *p, *q;

    language_init();
    lang = textcat_Classify(textcats, src, len > 512 ? 512 : len);

    if (!strcmp(lang, "UNKNOWN") || strlen(lang) < 3 || *lang != '[') {
        return NULL;
    }

    p = lang + 1;
    q = strchr(p, ']');
    if (!q) {
        return NULL;
    }

    return xstrndup(p, q - p);
}

EXPORTED char *language_detect_cs(const char *src, size_t len, charset_index cs, int encoding)
{
    char *s;
    char *lang;

    s = charset_to_utf8(src, len, cs, encoding);
    if (!s) return NULL;

    lang = language_detect(s, strlen(s));

    free(s);
    return lang;
}

#else /* ENABLE_LIBTEXTCAT */

EXPORTED const char *language_detect(const char *src, size_t len)
{
    return language_detectcs(src, len, CHARSET_UNKNOWN, 0);
}

EXPORTED const char *language_detect_cs(const char *src __attribute__((unused)),
                                        size_t len __attribute__((unused)),
                                        charset_index cs __attribute__((unused)),
                                        int encoding __attribute__((unused)))
{
    return NULL;
}

#endif /* ENABLE_LIBTEXTCAT */
