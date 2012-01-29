/* -*- Mode: C; tab-width: 4; indent-tabs-mode: nil; c-basic-offset: 4 -*- */
/*
 * libdatrie - Double-Array Trie Library
 * Copyright (C) 2006  Theppitak Karoonboonyanan <thep@linux.thai.net>
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
 */

/*
 * alpha-map.h - map between character codes and trie alphabet
 * Created: 2006-08-19
 * Author:  Theppitak Karoonboonyanan <thep@linux.thai.net>
 */

#ifndef __ALPHA_MAP_H
#define __ALPHA_MAP_H

#include <stdio.h>

#include "typedefs.h"
#include "triedefs.h"

/**
 * @file alpha-map.h
 * @brief AlphaMap data type and functions
 */

/**
 * @brief AlphaMap data type
 */
typedef struct _AlphaMap    AlphaMap;

AlphaMap *  alpha_map_new ();

AlphaMap *  alpha_map_clone (const AlphaMap *a_map);

void        alpha_map_free (AlphaMap *alpha_map);

int         alpha_map_add_range (AlphaMap  *alpha_map,
                                 AlphaChar  begin,
                                 AlphaChar  end);

int         alpha_char_strlen (const AlphaChar *str);

#endif /* __ALPHA_MAP_H */


/*
vi:ts=4:ai:expandtab
*/
