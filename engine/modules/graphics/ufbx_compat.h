#pragma once

#include "ufbx.h"

ufbx_node_list* ufbx_scene_GetNodeListFromScene( ufbx_scene* scene )
{
    return &(scene->nodes);
}

ufbx_string* ufbx_node_GetName( ufbx_node* node )
{
    return &node->name;
}
