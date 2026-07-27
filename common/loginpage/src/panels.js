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

'use strict';
$(document).ready(function() {
    const _toolmenu_tpl = `
            <div class="main-column col-left tool-menu">
              <li class="menu-item">
                <a action="recents">
                    <div class="icon-box">
                        <svg class="icon" data-iconname="home" data-precls="tool-icon">
                            <use href="#home"></use>
                        </svg>
                    </div>
                    <span class="text" l10n>${utils.Lang.actHome}</span>
                </a>
              </li>
              <li class="menu-item">
                <a action="open">
                    <div class="icon-box">
                        <svg class="icon" data-iconname="folder" data-precls="tool-icon">
                            <use href="#folder"></use>
                        </svg>
                    </div>
                    <span class="text" l10n>${utils.Lang.actOpenLocal}</span>
                </a>
              </li>
              <li class="menu-item">
                <a l10n action="templates">
                    <div class="icon-box">
                        <svg class="icon" data-iconname="templates" data-precls="tool-icon">
                            <use href="#templates"></use>
                        </svg>
                    </div>
                    <span class="text" l10n>${utils.Lang.actTemplates}</span>
                </a>
              </li>
              <li class="menu-item separator"></li>
              <section id="idx-sidebar-portals" class="connect">
              </section>
              <li class="menu-item devider"></li>
              <!-- SCRIVAR-REBRAND: Cloud & AI rail entry (opens the launcher manage window via scrivar-office://manage) -->
              <li class="menu-item">
                <a action="custom-cloudai">
                    <div class="icon-box">
                        <svg class="icon" data-iconname="aichat" data-precls="tool-icon">
                            <use href="#aichat"></use>
                        </svg>
                    </div>
                    <span class="text" l10n>${utils.Lang.actCloudAI}</span>
                </a>
              </li>
              <!-- SCRIVAR-REBRAND: Help & contact rail entry (opens the launcher support form via scrivar-office://support) -->
              <li class="menu-item">
                <a action="custom-support">
                    <div class="icon-box">
                        <svg class="icon" data-iconname="about" data-precls="tool-icon">
                            <use href="#about"></use>
                        </svg>
                    </div>
                    <span class="text" l10n>${utils.Lang.actHelpContact}</span>
                </a>
              </li>
              <li class="menu-item">
                  <a action="settings">
                    <div class="icon-box">
                      <svg class="icon" data-iconname="settings" data-precls="tool-icon">
                          <use href="#settings"></use>
                      </svg>
                    </div>
                    <span class="text" l10n>${utils.Lang.actSettings}</span>
                  </a>
              </li>
              <li class="menu-item hidden">
                  <a action="about">
                    <div class="icon-box">
                      <svg class="icon" data-iconname="about" data-precls="tool-icon">
                          <use href="#about"></use>
                      </svg>
                    </div>
                    <span class="text" l10n>${utils.Lang.actAbout}</span>
                  </a>
              </li>
              <!-- SCRIVAR-REBRAND: update footer (status from the launcher's loopback API) -->
              <li class="menu-item" id="scrivar-update-foot" style="display:none;margin-top:auto;padding:10px 12px 4px;cursor:pointer;">
                <div id="scrivar-update-version" style="font-size:11px;color:rgba(255,255,255,.55);line-height:1.5;"></div>
                <div id="scrivar-update-chip" style="display:none;margin-top:5px;font-size:11px;font-weight:600;padding:3px 9px;border-radius:999px;background:rgba(255,255,255,.16);color:#fff;"></div>
                <div id="scrivar-update-bar" style="display:none;margin-top:6px;height:3px;border-radius:2px;background:rgba(255,255,255,.18);overflow:hidden;">
                  <div id="scrivar-update-bar-fill" style="height:100%;width:0%;background:#fff;transition:width .25s ease;"></div>
                </div>
              </li>
            </div>
            <div class="main-column col-center after-left">
            </div>`;
    $('#placeholder').html(_toolmenu_tpl);

    $('.tool-menu').on('click', '> .menu-item > a', onActionClick);

    /* SCRIVAR-REBRAND: update footer — render the launcher's update state.
       The fork holds no update logic: it GETs status from the resident
       launcher over loopback and POSTs the user's intent back. If the launcher
       is not up (or this is not a Scrivar build) every call fails and the whole
       footer stays hidden, so nothing here can break the start page. */
    (function scrivarUpdateFooter() {
        var API = 'http://127.0.0.1:41317';
        var el = {
            root: document.getElementById('scrivar-update-foot'),
            version: document.getElementById('scrivar-update-version'),
            chip: document.getElementById('scrivar-update-chip'),
            bar: document.getElementById('scrivar-update-bar'),
            fill: document.getElementById('scrivar-update-bar-fill')
        };
        if (!el.root) return;
        var last = null;
        var busy = false;

        function post(path, body) {
            return fetch(API + path, {
                method: 'POST',
                headers: {'Content-Type': 'application/json'},
                body: JSON.stringify(body || {})
            }).catch(function(){ return null; });
        }

        function render(s) {
            last = s;
            el.root.style.display = 'block';
            el.version.textContent = utils.Lang.updVersion + ' ' + (s.currentVersion || '');
            var chip = '', bar = false, pct = 0;
            if (s.state === 'checking')          { chip = utils.Lang.updChecking; }
            else if (s.state === 'downloading')  { chip = utils.Lang.updDownloading + ' ' + (s.percent||0) + '%'; bar = true; pct = s.percent||0; }
            else if (s.canInstall)               { chip = utils.Lang.updRestart; }
            else if (s.state === 'available')    { chip = utils.Lang.updUpdateTo + ' ' + (s.targetVersion||''); }
            else if (s.state === 'error')        { chip = utils.Lang.updFailed; }
            el.chip.textContent = chip;
            el.chip.style.display = chip ? 'inline-block' : 'none';
            el.bar.style.display = bar ? 'block' : 'none';
            el.fill.style.width = pct + '%';
            el.root.title = chip || utils.Lang.settScrivarCheckUpdates;
        }

        function poll() {
            fetch(API + '/update/status', {cache: 'no-store'})
                .then(function(r){ return r.ok ? r.json() : null; })
                .then(function(s){ if (s && s.ok) render(s); else el.root.style.display = 'none'; })
                .catch(function(){ el.root.style.display = 'none'; });
        }

        el.root.addEventListener('click', function() {
            if (busy || !last) return;
            busy = true;
            setTimeout(function(){ busy = false; }, 800);
            if (last.canInstall) {
                /* The LAUNCHER asks this app to quit (Apple Event → save
                   prompts). We only signal intent; if the user cancels a save
                   prompt nothing installs and the footer stays as it was. */
                post('/update/restart');
            } else if (last.state === 'available') {
                post('/update/download');
            } else if (last.state !== 'downloading' && last.state !== 'checking') {
                post('/update/check');
            }
            setTimeout(poll, 300);
        });

        poll();
        setInterval(poll, 1500);
    })();
    /* SCRIVAR-REBRAND: Help & contact rail — open the resident launcher's support
       form. window.open on a custom scheme is intercepted by CEF and handed to the
       OS (LaunchServices) → the scrivar-office:// handler (the launcher). No
       account/ticket/endpoint logic in the fork — just this URL. */
    $('.tool-menu').on('click', '> .menu-item > a[action="custom-support"]', function(e) {
        e.preventDefault();
        window.open('scrivar-office://support');
    });
    /* SCRIVAR-REBRAND: Cloud & AI rail — open the resident launcher's manage window.
       window.open on a custom scheme is intercepted by CEF and handed to the OS
       (LaunchServices) → the scrivar-office:// handler (the launcher). No account/
       token/billing logic in the fork — just this URL. */
    $('.tool-menu').on('click', '> .menu-item > a[action="custom-cloudai"]', function(e) {
        e.preventDefault();
        window.open('scrivar-office://manage');
    });
    // $('.tool-quick-menu .menu-item a').click(onNewFileClick);

    if ( window.utils.isWinXp ) {
        $(document.body).addClass('win_xp');
        $('a[action] use').each((i, e) => {
            const _attr_href = e.getAttribute('href');
            if ( !!_attr_href ) {
                const $el = $(e), $parent = $el.parent();
                $el.remove();
                $parent.html(`<use xlink:href="${_attr_href}"></use>`);
            }
        });
    }

    !window.app && (window.app = {controller:{}});
    !window.app.controller && (window.app.controller = {});

    if ( !!window.ControllerTemplates )
        window.app.controller.templates = (new ControllerTemplates).init();
    window.app.controller.recent = (new ControllerRecent).init();
    window.app.controller.folders = (new ControllerFolders).init();
    window.app.controller.about = (new ControllerAbout).init();
    window.app.controller.settings = (new ControllerSettings).init();

    if (!!window.ControllerPortals)
        window.app.controller.portals = (new ControllerPortals({
            placeholder: '#idx-sidebar-portals',
        })).init();

    !!window.ControllerExternalPanel && (window.app.controller.externalpanel = (new ControllerExternalPanel({})).init());

    // if (!localStorage.welcome) {
    //     app.controller.welcome = (new ControllerWelcome).init();
    //     selectAction('welcome');

    //     localStorage.setItem('welcome', 'have been');
    // } else
    {
        if ( !!utils.inParams.panel && $(`.action-panel.${utils.inParams.panel}`).length )
            selectAction(utils.inParams.panel);
        else selectAction('recents');
    }

    $('#placeholder').on('click', '.newportal', function(){
        CommonEvents.fire("portal:create");
    });

    if (!window.config.portals.checklist || !window.config.portals.checklist.length) { /* SCRIVAR-REBRAND (P3): sortProviders() returns [] (truthy) — an EMPTY provider checklist must hide the Clouds surface too */
        $('.tools-connect').hide();
        hideAction('connect');
        $('#idx-sidebar-portals').hide(); /* SCRIVAR-REBRAND (P3): the Clouds sidebar section (header + "+" button) is its own block — hiding the advert/action alone leaves an empty "Clouds +" rail entry */
        console.log('There are no cloud providers');
    }

    if (!utils.inParams.waitingloader)
        setLoaderVisible(false);

    /* test information */
    // var arr = [
    //     {"id":0,"type":utils.defines.FileFormat.FILE_CROSSPLATFORM_PDF,"path":"https://testinfo.teamlab.info/New Document.docx","modifyed":"11.12.2015 18:45"},
    //     {"id":1,"type":utils.defines.FileFormat.FILE_CROSSPLATFORM_DJVU,"path":"C:\\Users\\maxim.kadushkin\\Documents\\DPIConfig_SmallPCs.docx","modifyed":"11.12.2015 18:22"},
    //     {"id":2,"type":utils.defines.FileFormat.FILE_CROSSPLATFORM_XPS,"path":"/Users/ayuzhin/Develop/Web/test.html","modifyed":"11.12.2015 17:58"},
    //     {"id":3,"type":utils.defines.FileFormat.FILE_PRESENTATION_PPTX,"path":"https://testinfo.teamlab.info\\Sadfasd.docx","modifyed":"10.12.2015 17:25"},
    //     {"id":4,"type":utils.defines.FileFormat.FILE_SPREADSHEET_CSV,"path":"https://testinfo.teamlab.info\\Sadfasd.docx","modifyed":"10.12.2015 17:25"},
    //     {"id":5,"type":utils.defines.FileFormat.FILE_SPREADSHEET_ODS,"path":"https://testinfo.teamlab.info\\Sadfasd.docx","modifyed":"10.12.2015 17:25"},
    //     {"id":6,"type":utils.defines.FileFormat.FILE_SPREADSHEET_XLS,"path":"https://testinfo.teamlab.info\\Office 365 Value Added Reseller Guide.docx","modifyed":"10.12.2015 16:46"}
    // ];
    // window.onupdaterecents(arr);
    // window.onupdaterecovers(arr);
    /* **************** */

    setTimeout(()=>{
        if (window.sdk) {
            window.sdk.LocalFileRecovers();
            window.sdk.LocalFileRecents();

            window.sdk.execCommand('app:onready', '');
        } 
    }, 50);

    $('.scrollable').on('scroll', e => {
        if ( window.Menu && Menu.opened ) {
            Menu.closeAll();
        }
    });

    const mq = "screen and (-webkit-min-device-pixel-ratio: 1.01) and (-webkit-max-device-pixel-ratio: 1.99), " +
                                "screen and (min-resolution: 1.01dppx) and (max-resolution: 1.99dppx)";

    const mql = window.matchMedia(mq);
    mql.addEventListener('change', e => {
        CommonEvents.fire("icons:svg", [!e.target.matches]);
        replaceIcons(!e.target.matches);
    });

    replaceIcons(!mql.matches);
});

function onActionClick(e) {
    var $el = $(this);
    var action = $el.attr('action');
    const pinned = JSON.parse(localStorage.getItem('pinnedFolders') || '[]');

    if (/^custom/.test(action)) return;

    if (action == 'open' && 
            !app.controller.recent.getRecents().size() && 
                !app.controller.recent.getRecovers().size() &&
                    !pinned.length) 
    {
        openFile(OPEN_FILE_FOLDER, '');
    } else {
        if (action === 'about') {
            return CommonEvents.fire('panel:show', [action]);
        }
        $('.tool-menu > .menu-item').removeClass('selected');
        $el.parent().addClass('selected');
        $('.action-panel').hide();
        $('.action-panel.' + action).show(0,()=>{
            // bug: recent panel has the wrong height if 'wellcome' panel is showed firstly
            // if (action == 'recent') {
            //     app.controller.recent.view.updateListSize();
            // }
        });

        CommonEvents.fire('panel:show', [action]);
    }
};

function selectAction(action) {
    if ( !$(`.action-panel.${action}`).length ) return;

    if (action === 'about') {
            return CommonEvents.fire('panel:show', [action]);
    }
    $('.tool-menu > .menu-item').removeClass('selected');
    $('.tool-menu a[action='+action+']').parent().addClass('selected');
    $('.action-panel').hide();
    $('.action-panel.' + action).show();

    CommonEvents.fire('panel:show', [action]);
};

function hideAction(action, hide) {
    if ( action == 'connect' ) {
        hide ? $('#idx-sidebar-portals').hide() :
                $('#idx-sidebar-portals').show();
        return;
    }

    var mitem = $('.tool-menu a[action='+action+']').parent();
    mitem.removeClass('extra')[hide===false?'show':'hide']();
    $('.action-panel.' + action)[hide===false?'show':'hide']();
};

function setLoaderVisible(isvisible, timeout) {
    setTimeout(function(){
        $('#loading-mask')[isvisible?'show':'hide']();
    }, timeout || 200);
}

var OPEN_FILE_RECOVERY = 1;
var OPEN_FILE_RECENT = 2;
var OPEN_FILE_FOLDER = 3;
var Scroll_offset = '16px';

{
    // const mq = "screen and (-webkit-min-device-pixel-ratio: 1.01) and (-webkit-max-device-pixel-ratio: 1.99), " +
    //                             "screen and (min-resolution: 1.01dppx) and (max-resolution: 1.99dppx)";

    // const mql = window.matchMedia(mq);
    // mql.addEventListener('change', e => {
    //     CommonEvents.fire("icons:svg", [!e.target.matches]);
    //     replaceIcons(!e.target.matches);
    // });

    // replaceIcons(!mql.matches);
}

function replaceIcons(usesvg) {
    if ( usesvg ) {
    } else {
        $('.tool-menu svg.icon').each((i, el) => {
            el = $(el);
            const p = el.parent();
            if ( $('i.icon', p).length == 0 ) {
                const icon_pre_class = el.data("precls");
                const icon_class = el.data("iconname");
                const t = `<i class="icon ${icon_pre_class? icon_pre_class : ''} ${icon_class}" />`;
                $(t).insertAfter(el);
            }
        });
    }
}

function onNewFileClick(e) {
    if ($(e.currentTarget).parent().hasClass('disabled'))
        return;
    
    var me = this;
    if (me.click_lock===true) return;
    me.click_lock = true;

    var t;
    switch (e.currentTarget.attributes['action'].value) {
    case 'new:docx': t = 'word'; break;
    case 'new:xlsx': t = 'cell'; break;
    case 'new:pptx': t = 'slide'; break;
    case 'new:form': t = 'form'; break;
    default: break;
    }

    if ( !!t ) window.sdk.command("create:new", t);

    setTimeout(function(){
        me.click_lock = false;
    }, utils.defines.DBLCLICK_LOCK_TIMEOUT);
}

window.sdk.on('on_native_message', function(cmd, param) {
    let _re_res;
    if (cmd == 'portal:logout') {
        // var short_name = utils.skipUrlProtocol(param);
        // var model = portalCollection.find('name', short_name);
        // !!model && model.set('logged', false);
    } else
    if ( (_re_res = /^panel\:(hide|show|select)/.exec(cmd)) ) {
        let panel = param;
        if ( _re_res[1] == 'select' ) {
            selectAction( panel );
        } else {
            let hide = !(_re_res[1] == 'show');

            if ( panel.length ) {
                hideAction(panel, hide);
            }
        }
    } else
    if (/app\:ready/.test(cmd)) {
        setLoaderVisible(false);
    } else
    if (/app\:version/.test(cmd)) {
        $('.tool-menu a[action=about]').parent().removeClass('hidden');
    }
    
    console.log(cmd, param);
});

window.last_click_time = performance.now();
function openFile(from, model) {
    if (window.sdk) {
        if ( performance.now() - last_click_time < 1000 ) return;
        last_click_time = performance.now();

        if (from == OPEN_FILE_FOLDER) {
            window.sdk.command("open:folder", model);
        } else {
            const params = {
                    id: model.fileid,
                    name: utils.fn.decodeHtml(model.name),
                    path: utils.fn.decodeHtml(model.path),
                    type: model.type,
                    cloud: model.cloud,
                    hash: model.hash,
                    recovery: from == OPEN_FILE_RECOVERY,
                };

            // if ( from == OPEN_FILE_RECOVERY ) {
                // window.sdk.LocalFileOpenRecover(parseInt(params.id));       // for bug 60509. change on "open:recovery" event for ver 7.4
                // window.sdk.command("open:recovery", JSON.stringify(params));
            // } else {
                // window.sdk.LocalFileOpenRecent(parseInt(params.id));        // for bug 60509. change on "open:recent" event for ver 7.4
                window.sdk.command("open:recent", JSON.stringify(params));
            // }
        }
    } 
}

document.getElementById('wrap').ondrop = function(e) {
    window.sdk["DropOfficeFiles"]();

    e.preventDefault();
    return false;
}

document.getElementById('wrap').ondragover = function (e) {
    e.dataTransfer.dropEffect = 'copy';

    e.preventDefault();
    return false;
};

$(document).on('keydown', function(e){
    if ( e.ctrlKey && e.which == 79 ) {
        if ($('.action-panel').filter('.recents, .open, .welcome').is(':visible')) {
            openFile(OPEN_FILE_FOLDER, '');
        }
    }
});

window.addEventListener('message', e => {
    let msg = window.JSON.parse(e.data);
    if ( msg.type == 'plugin' ) {
        if ( !!msg.event ) {
            if ( msg.event == 'modal:open' )
                $('.main-column.tool-menu').addClass('view--modal')
            else $('.main-column.tool-menu').removeClass('view--modal');
        } else sdk.fire('on_native_message', Object.values(msg.data));
    }
}, false);
