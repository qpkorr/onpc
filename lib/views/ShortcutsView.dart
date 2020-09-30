/*
 * Copyright (C) 2020. Mikhail Kulesh
 *
 * This program is free software: you can redistribute it and/or modify it under the terms of the GNU
 * General Public License as published by the Free Software Foundation, either version 3 of the License,
 * or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without
 * even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details. You should have received a copy of the GNU General
 * Public License along with this program.
 */

import "package:flutter/material.dart";
import "package:positioned_tap_detector/positioned_tap_detector.dart";
import "package:sprintf/sprintf.dart";

import "../config/CfgAppSettings.dart";
import "../config/CfgFavoriteShortcuts.dart";
import "../constants/Dimens.dart";
import "../constants/Drawables.dart";
import "../constants/Strings.dart";
import "../dialogs/FavoriteShortcutEditDialog.dart";
import "../iscp/StateManager.dart";
import "../utils/Logging.dart";
import "../views/UpdatableView.dart";
import "../widgets/CustomImageButton.dart";
import "../widgets/CustomTextLabel.dart";

enum _ShortcutContextMenu
{
    EDIT,
    DELETE
}

class ShortcutsView extends UpdatableView
{
    static const List<String> UPDATE_TRIGGERS = [
        FavoriteShortcutEditDialog.SHORTCUT_CHANGE_EVENT
    ];

    ShortcutsView(final ViewContext viewContext) : super(viewContext, UPDATE_TRIGGERS);

    @override
    Widget createView(BuildContext context, VoidCallback updateCallback)
    {
        Logging.info(this, "rebuild widget");

        if (configuration.favoriteShortcuts.shortcuts.isEmpty)
        {
            final String message = sprintf(Strings.favorite_shortcut_howto,
                [CfgAppSettings.getTabName(AppTabs.MEDIA), Strings.favorite_shortcut_create]);
            return CustomTextLabel.small(message, textAlign: TextAlign.center);
        }

        final List<Widget> rows = List<Widget>();
        configuration.favoriteShortcuts.shortcuts.forEach((s)
        => rows.add(_buildRow(context, s)));

        return Expanded(
            flex: 1,
            child: ReorderableListView(
            onReorder: _onReorder,
                reverse: false,
                scrollDirection: Axis.vertical,
                children: rows)
        );
    }

    Widget _buildRow(final BuildContext context, final Shortcut s)
    {
        String serviceIcon = s.service.icon;
        if (serviceIcon == null)
        {
            serviceIcon = Drawables.media_item_unknown;
        }
        final Widget w = PositionedTapDetector(
            child: ListTile(
                contentPadding: EdgeInsets.symmetric(horizontal: MediaListDimens.itemPadding),
                dense: configuration.appSettings.textSize != "huge",
                leading: CustomImageButton.normal(
                    serviceIcon, null,
                    isEnabled: false,
                    padding: EdgeInsets.symmetric(vertical: MediaListDimens.itemPadding),
                ),
                title: CustomTextLabel.normal(s.alias),
                onTap: ()
                => _selectShortcut(s)
            ),
            onLongPress: (position)
            => _onCreateContextMenu(context, position, s),
        );
        return Row(
            key: Key(s.id.toString()),
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [Expanded(child: w), Icon(Icons.drag_handle)]
        );
    }

    void _onCreateContextMenu(final BuildContext context, final TapPosition position, final Shortcut s)
    {
        final List<PopupMenuItem<_ShortcutContextMenu>> contextMenu = List<PopupMenuItem<_ShortcutContextMenu>>();
        contextMenu.add(PopupMenuItem<_ShortcutContextMenu>(
            child: CustomTextLabel.small(Strings.favorite_shortcut_edit), enabled: false));
        contextMenu.add(PopupMenuItem<_ShortcutContextMenu>(
            child: Text(Strings.favorite_update), value: _ShortcutContextMenu.EDIT));
        contextMenu.add(PopupMenuItem<_ShortcutContextMenu>(
            child: Text(Strings.favorite_delete), value: _ShortcutContextMenu.DELETE));

        showMenu(
            context: context,
            position: RelativeRect.fromLTRB(position.global.dx, position.global.dy, position.global.dx, position.global.dy),
            items: contextMenu).then((m)
        => _onContextItemSelected(context, m, s)
        );
    }

    void _onContextItemSelected(final BuildContext context, final _ShortcutContextMenu m, final Shortcut s)
    {
        if (m == null)
        {
            return;
        }
        Logging.info(this, "selected context menu: " + m.toString() + ", shortcut: " + s.toString());
        switch (m)
        {
            case _ShortcutContextMenu.EDIT:
                showDialog(
                    context: context,
                    barrierDismissible: true,
                    builder: (BuildContext c)
                    => FavoriteShortcutEditDialog(viewContext, s)
                );
                break;
            case _ShortcutContextMenu.DELETE:
                configuration.favoriteShortcuts.deleteShortcut(s);
                stateManager.triggerStateEvent(FavoriteShortcutEditDialog.SHORTCUT_CHANGE_EVENT);
                break;
        }
    }

    void _onReorder(int oldIndex, int newIndex)
    {
        if (newIndex > oldIndex)
        {
            newIndex -= 1;
        }
        configuration.favoriteShortcuts.reorder(oldIndex, newIndex);
        stateManager.triggerStateEvent(FavoriteShortcutEditDialog.SHORTCUT_CHANGE_EVENT);
    }

    void _selectShortcut(Shortcut s)
    {
        if (state.isConnected)
        {
            stateManager.applyShortcut(s);
            stateManager.triggerStateEvent(StateManager.APPLY_FAVORITE_EVENT);
        }
    }
}