/*
 * Copyright (C) Ascensio System SIA, 2009-2026
 *
 * This program is a free software product. You can redistribute it and/or
 * modify it under the terms of the GNU Affero General Public License (AGPL)
 * version 3 as published by the Free Software Foundation, together with the
 * additional terms provided in the LICENSE file.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without even the implied
 * warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. For
 * details, see the GNU AGPL at: https://www.gnu.org/licenses/agpl-3.0.html
 *
 * You can contact Ascensio System SIA by email at info@onlyoffice.com
 * or by postal mail at 20A-6 Ernesta Birznieka-Upisha Street, Riga,
 * LV-1050, Latvia, European Union.
 *
 * The interactive user interfaces in modified versions of the Program
 * are required to display Appropriate Legal Notices in accordance with
 * Section 5 of the GNU AGPL version 3.
 *
 * No trademark rights are granted under this License.
 *
 * All non-code elements of the Product, including illustrations,
 * icon sets, and technical writing content, are licensed under the
 * Creative Commons Attribution-ShareAlike 4.0 International License:
 * https://creativecommons.org/licenses/by-sa/4.0/legalcode
 *
 * This license applies only to such non-code elements and does not
 * modify or replace the licensing terms applicable to the Program's
 * source code, which remains licensed under the GNU Affero General
 * Public License v3.
 *
 * SPDX-License-Identifier: AGPL-3.0-only
 */

#ifndef DEFINES_H
#define DEFINES_H

#define rePortalName        "^https?:\\/\\/(.+)"
#define reFileExtension     "\\.(\\w{1,10})$"
#define reUserName          "([^\\.]+)\\.?([^\\.]+)?"
#define reCmdLang           "--(keep)?lang[:|=](\\w{2,5})"

#define APP_NAME "DesktopEditors"
// SCRIVAR-REBRAND: display name only (editor window title label). Same policy as
// scrivar-rebrand/sweep-strings.sh on mac — user-visible product name changes,
// while legal notices, copyright headers and bundle-internal identifiers below
// (APP_NAME, APP_DATA_PATH, REG_*, APP_MUTEX_NAME) are deliberately left alone:
// AGPL notices stay, and the storage keys must not move.
#define APP_TITLE "Scrivar Office"
#ifdef __linux
# define APP_DATA_PATH "/onlyoffice/desktopeditors"
# define REG_GROUP_KEY "onlyoffice"
# define APP_MUTEX_NAME "asc:editors"
# define DESKTOP_FILE_NAME "onlyoffice-desktopeditors"
#else
# define APP_DATA_PATH "/ONLYOFFICE/DesktopEditors"
# define APP_REG_NAME  "ONLYOFFICE"
# define REG_GROUP_KEY "ONLYOFFICE"
# define REG_UNINST_KEY "ONLYOFFICE Desktop Editors"
# define APP_MUTEX_NAME "TEAMLAB"
#endif

// SCRIVAR-REBRAND: display name only — feeds QCoreApplication::setApplicationName,
// setApplicationDisplayName and the file-association prompts. Verified nothing
// derives a settings path from applicationName() (registry storage goes through
// REG_GROUP_KEY/REG_APP_NAME, which are untouched), so renaming moves no data.
#define WINDOW_NAME "Scrivar Office"
#define WINDOW_TITLE WINDOW_NAME
#define WINDOW_CLASS_NAME L"DocEditorsWindowClass"
#define WINDOW_EDITOR_CLASS_NAME L"SingleWindowClass"
#define REG_APP_NAME "DesktopEditors"
#define APP_DEFAULT_LOCALE "en-US"
#define APP_DEFAULT_SYSTEM_LOCALE 1
#define APP_USER_MODEL_ID "ASC.Documents.5"
#define APP_SIMPLE_WINDOW_TITLE "ONLYOFFICE Editor"
#define APP_PROTOCOL "oo-office"
#define FILE_PREFIX "onlyoffice_"

#define URL_SITE                "http://www.onlyoffice.com"
#define URL_SIGNUP              "https://onlyoffice.com/registration.aspx?desktop=true"

#define GET_REGISTRY_USER(variable) \
    QSettings variable(QSettings::NativeFormat, QSettings::UserScope, REG_GROUP_KEY, REG_APP_NAME);
#define GET_REGISTRY_SYSTEM(variable) \
    QSettings variable(QSettings::SystemScope, REG_GROUP_KEY, REG_APP_NAME);

#define LOCAL_PATH_OPEN         1
#define LOCAL_PATH_SAVE         2

#define ACTIONPANEL_CONNECT     255
#define ACTIONPANEL_ACTIVATE    ACTIONPANEL_CONNECT + 1

// SCRIVAR-REBRAND: URL_AGPL stays as-is on purpose — it is the AGPL section 5
// "Appropriate Legal Notices" link rendered in the About panel, and it must
// keep pointing at the real licence text.
#define URL_AGPL "https://www.gnu.org/licenses/agpl-3.0.en.html"
// SCRIVAR-REBRAND: repointed away from onlyoffice.com. Both of these are only
// referenced from cupdatemanager.cpp, which is compiled out now that
// _UPDMODULE is off (see ASCDocumentEditor.pro) — repointed anyway so a grep of
// the shipped binary for upstream URLs is provably clean, and so re-enabling
// the module could never resurrect an upstream link.
#define DOWNLOAD_PAGE "https://scrivar.com/office/help"
// Empty is a supported value: callers guard with
// `if (!QString(RELEASE_NOTES).isEmpty())`, so this cleanly drops the link
// rather than pointing customers at the upstream changelog.
#define RELEASE_NOTES ""

#ifdef __linux
typedef unsigned char BYTE;
#else
# define UM_INSTALL_UPDATE      WM_USER+254
#endif

#define UM_ENDMOVE (QEvent::User + 2)

#define TO_WSTR(str)            L ## str
#define WSTR(str)               TO_WSTR(str)

#ifdef __linux
# define VK_F1 0x70
# define VK_F4 0x73
# define VK_TAB 0x09
#endif

#define APP_PORT   12010
#define SVC_PORT   12011
#define INSTANCE_SVC_PORT 12012
#define INSTANCE_APP_PORT 13012

#define WARNING_LAUNCH_WITH_ADMIN_RIGHTS "App can't working correctly under admin rights."

#include "defines_p.h"

#endif // DEFINES_H

