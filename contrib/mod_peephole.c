/* ====================================================================
 * Copyright (c) 1995-1997 The Apache Group.  All rights reserved.
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
 * 3. All advertising materials mentioning features or use of this
 *    software must display the following acknowledgment:
 *    "This product includes software developed by the Apache Group
 *    for use in the Apache HTTP server project (http://www.apache.org/)."
 *
 * 4. The names "Apache Server" and "Apache Group" must not be used to
 *    endorse or promote products derived from this software without
 *    prior written permission.
 *
 * 5. Redistributions of any form whatsoever must retain the following
 *    acknowledgment:
 *    "This product includes software developed by the Apache Group
 *    for use in the Apache HTTP server project (http://www.apache.org/)."
 *
 * THIS SOFTWARE IS PROVIDED BY THE APACHE GROUP ``AS IS'' AND ANY
 * EXPRESSED OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE APACHE GROUP OR
 * ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
 * NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 * ====================================================================
 *
 * This software consists of voluntary contributions made by many
 * individuals on behalf of the Apache Group and was originally based
 * on public domain software written at the National Center for
 * Supercomputing Applications, University of Illinois, Urbana-Champaign.
 * For more information on the Apache Group and the Apache HTTP server
 * project, please see <http://www.apache.org/>.
 *
 */

/*
**  mod_peephole.c -- Apache API module for opening a peephole 
**                    to a documents filesystem informations.
**                       _                            _           _      
**   _ __ ___   ___   __| |     _ __   ___  ___ _ __ | |__   ___ | | ___ 
**  | '_ ` _ \ / _ \ / _` |    | '_ \ / _ \/ _ \ '_ \| '_ \ / _ \| |/ _ \
**  | | | | | | (_) | (_| |    | |_) |  __/  __/ |_) | | | | (_) | |  __/
**  |_| |_| |_|\___/ \__,_|____| .__/ \___|\___| .__/|_| |_|\___/|_|\___|
**                       |_____|_|             |_|                       
**
**  Peephole Module, Version 1.0.0 (11-Jul-1997)
**
**  This module opens a peephole to the document informations
**  on the servers filesystem. It enables a client to retrieve
**  informations about an URLs source which else cannot be
**  accessed via HTTP like the mapped filesystem path, the real
**  modification time or the owner.
**
**  The reason why this module was written was the fact that the last 
**  modification time of a CGI script or a SSI document cannot determined
**  via the HTTP response header Last-Modified because there usually 
**  is no such one due to the nature of CGI or SSI generated data.
**  But a webagent like LCWA (http://www.engelschall.com/sw/lcwa/)
**  which should determine the latest changes in an Intranet is really
**  interested in the modification time _OF THE SOURCE_ and not the
**  generated data. So, when it made a request for URL /a/b/c on some
**  Apache webserver and did not receive a Last-Modified header it
**  now has to the chance to do a second request for URL /peep/a/b/c
**  and receive the information this way.
**
**  Copyright (c) 1997 Ralf S. Engelschall, All rights reserved.
**
**  Written for The Apache Group by
**      Ralf S. Engelschall
**      rse@engelschall.com
**      www.engelschall.com
*/

/*  MODULE DESCRIPTION:

    Goal: A request to URL /peep/a/b/c/ should lead to the normal processing for
          URL /a/b/c including internal redirects (implicit ones via mod_dir
          DirectoryIndex, or explicit ones via mod_rewrite rules), but instead
          of the final output a short and easy to parse page should be send
          from where the real MTime and Owner can be determined.
   
    Problems: First, the API does not provide any content handler nesting
          or content filtering, so we have no chance to interface the
          processing _after_ a content handler was run. Second, due to
          internal redirects and subrequests we need to remember the
          peepholing in any way. Third, we cannot use a wildcard handler because
          these are called too late. Forth we cannot always set the r->handler
          to ourself and there redirect to another handler (does not work, 
          because invoke_method() in the core does compare always with the same
          r->handler copy).

    Solution: We use the URI-to-filename hook to remove the /peep prefix
          and just remember the fact that we are called. Then we use
          the fixup hook (the one before the content handler are called)
          to decide if our content handler should be activated. We also
          filter out the situations of mod_dir and mod_rewrite cases.
          Finally we use an own content handler to send the page.

    INSTALLATION:

    Copy this file to your Apache sourcedir apache-1.2.X/src/ and add the
    following line _TO THE END_ of your apache-1.2.X/src/Configuration file:

        Module peephole_module mod_peephole.o

    The position at the end is important because it has to be able to
    act before mod_rewrite and mod_dir, etc.

    TODO-LIST:

    - Directives to make it more secure:
      "PeepholePrefix <prefix>"
      "PeepholeAccessOrder allow,deny"
      "PeepholeAccessAllow host <regex>, ip <ip>, browser <regex>"
      "PeepholeAccessDeny  host <regex>, ip <ip>, browser <regex>"
      "PeepholeDetails     mtime,owner,..."

*/

#include "httpd.h"
#include "http_config.h"
#include "http_protocol.h"
#include "http_log.h"
#include "util_script.h"
#include "http_main.h"
#include "http_request.h"

#include <sys/types.h>
#include <pwd.h>


#define PEEPHOLE_PREFIX       "/peep"
#define PEEPHOLE_MAGIC_TYPE   "open-peephole"
#define PEEPHOLE_NOTICE_NAME  "peephole_indicator"
#define PEEPHOLE_NOTICE_VALUE "activated"


/* 
 *  get hook-persistent notice
 */
static void set_notice(request_rec *r, char *key, char *value)  
{
    if (value == NULL)
        table_set(r->notes, key, "<NULL>");
    else
        table_set(r->notes, key, value);
    return;
}

static char *get_notice(request_rec *r, char *key)  
{
    request_rec *req;
    char *value;

    /*  1. search in current request  */
    req = r;
    value = table_get(req->notes, key);
    if (value == NULL) {
        /*  2. search in all previous requests
         *     on internal redirects
         */
        while (req->prev != NULL) {
            req = req->prev;
            value = table_get(req->notes, key);
            if (value != NULL)
                break;
        }
        if (value == NULL) {
            /* 3. search in main request on subrequest */
            if (req->main != NULL) {
                req = req->main;
                value = table_get(req->notes, key);
                if (value == NULL) {
                    /*  4. search in all previous requests
                     *     on internal redirects inside main 
                     */
                    while (req->prev != NULL) {
                        req = req->prev;
                        value = table_get(req->notes, key);
                        if (value != NULL)
                            break;
                    }
                }
            }
        }
    }

    if (value == NULL)
        return NULL;
    if (strcmp(value, "<NULL>") == 0)
        return NULL;
    return value;
}


/*
 *  Apache API hook #1: URL-to-filename
 *  Task: Recognize the URL prefix, remember that fact
 */
int peephole_translate(request_rec *r)
{
    int l;

    /*  if we see an URL with our prefix, strip this
     *  prefix and just remember the fact that this indicates
     *  that we should threat it special
     */
    l = strlen(PEEPHOLE_PREFIX);
    if (strlen(r->uri) > l && strncmp(r->uri, PEEPHOLE_PREFIX, l) == 0) {
        r->uri = pstrdup(r->pool, r->uri+l);
        set_notice(r, PEEPHOLE_NOTICE_NAME, PEEPHOLE_NOTICE_VALUE);
    }

    /* say we have done nothing (which is true for the API
       because we have not done any URI-to-filename mapping ;-)
       even if we changed the URI itself... */
    return DECLINED;
}


/*
 *  Apache API hook #7: Fixup
 *  Task: Decide if our content should be actually used
 */
int peephole_fixup(request_rec *r)
{
    char *n;

    /*  decide if our service was used et all  */
    n = get_notice(r, PEEPHOLE_NOTICE_NAME);
    if (n == NULL)
        return DECLINED;
    if (strcmp(n, PEEPHOLE_NOTICE_VALUE) != 0)
        return DECLINED;

    /*  sort out situations where we (still!) don't use
     *  our content handler. It'll be used later in
     *  subrequests or after an internal redirect...
     */

    /* mod_rewrite redirects (in per-dir context) */
    if (strncmp(r->filename, "redirect:", 9) == 0)
        return DECLINED;
    if (r->handler != NULL && strcmp(r->handler, "redirect-handler") == 0)
        return DECLINED;

    /* mod_dir (DirectoryIndex files) */
    if (S_ISDIR(r->finfo.st_mode))
        return DECLINED;
    if (r->handler != NULL && strcmp(r->handler, DIR_MAGIC_TYPE) == 0)
        return DECLINED;

    /* general stuff */
    if (r->method_number != M_GET) 
        return DECLINED;

    /*  ok, now its time to activate our content handler
     *  because no exceptional situations matched.
     */
    r->handler = PEEPHOLE_MAGIC_TYPE;
    return OK;
}


/*
 *  Apache API hook #8: content handler
 *  Task: Actual processinf and generation of the result document
 */
int peephole_handler(request_rec *r)
{
    char ca[512];
    char *url;
    char *filename;
    struct passwd *pw;
    char *owner;
    char *mtime;
    int bytes;
    request_rec *req;
    char *date;

    /* is still all ok */
    if (r->status != HTTP_OK)
        return DECLINED;

    /*  first make sure that the file
     *  really exists we should act on
     */
    if (r->finfo.st_mode == 0) {
        log_reason("File does not exist", r->filename, r);
        return NOT_FOUND;
    }

    /*  Determine final filename (trivial)
     *  and initial URI (searched through request_rec list)
     */
    filename = r->filename;
    req = r;
    while (req->prev != NULL)
        req = req->prev;
    while (req->main != NULL)
        req = req->main;
    url = req->uri;

    /*  Determine file details */
    ap_snprintf(ca, sizeof(ca), "%d (%s)", 
        r->finfo.st_mtime,
        ht_time(r->pool, r->finfo.st_mtime, "%A, %d-%b-%y %T %Z", 0) );
    mtime = pstrdup(r->pool, ca);
    bytes = r->finfo.st_size;
    pw = getpwuid(r->finfo.st_uid);
    if (pw == NULL)
        owner = "-unknown-";
    else {
        ap_snprintf(ca, sizeof(ca), "%s (%s)", pw->pw_name, pw->pw_gecos);
        owner = pstrdup(r->pool, ca);
    }

    /*  Determine file details */
    date = ht_time(r->pool, time(0L), "%A, %d-%b-%y %T %Z", 0);

    /*  Send result document
     */
    r->content_type = "text/plain";      
    send_http_header(r);
    if(r->header_only)
        return OK; 
    ap_snprintf(ca, sizeof(ca), "Apache Peephole Information (%s):\n\n", date); rputs(ca, r);
    ap_snprintf(ca, sizeof(ca), "      URL: %s\n", url);      rputs(ca, r);
    ap_snprintf(ca, sizeof(ca), " Filename: %s\n", filename); rputs(ca, r);
    ap_snprintf(ca, sizeof(ca), "    Owner: %s\n", owner);    rputs(ca, r);
    ap_snprintf(ca, sizeof(ca), "    MTime: %s\n", mtime);    rputs(ca, r);
    ap_snprintf(ca, sizeof(ca), "    Bytes: %d\n", bytes);    rputs(ca, r);
    return OK;
}


/*
 *  The Apache API glue structures
 */

handler_rec peephole_handlers[] = {
    { PEEPHOLE_MAGIC_TYPE, peephole_handler },
    { NULL, NULL }
};

module peephole_module = {
   STANDARD_MODULE_STUFF,
   NULL,              /* initializer */
   NULL,              /* create per-directory config structure */
   NULL,              /* merge per-directory config structures */
   NULL,              /* create per-server config structure */
   NULL,              /* merge per-server config structures */
   NULL,              /* command table */
   peephole_handlers, /* handlers */
   peephole_translate,/* translate_handler */
   NULL,              /* check_user_id */
   NULL,              /* check auth */
   NULL,              /* check access */
   NULL,              /* type_checker */
   peephole_fixup,    /* pre-run fixups */
   NULL,              /* logger */
   NULL               /* header parser */
};


/*EOF*/
