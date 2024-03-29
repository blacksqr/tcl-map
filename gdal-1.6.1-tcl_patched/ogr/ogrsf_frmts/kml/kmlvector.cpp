/******************************************************************************
 * $Id: kmlvector.cpp 16909 2009-05-02 14:56:22Z rouault $
 *
 * Project:  KML Driver
 * Purpose:  Specialization of the kml class, only for vectors in kml files.
 * Author:   Jens Oberender, j.obi@troja.net
 *
 ******************************************************************************
 * Copyright (c) 2007, Jens Oberender
 *
 * Permission is hereby granted, free of charge, to any person obtaining a
 * copy of this software and associated documentation files (the "Software"),
 * to deal in the Software without restriction, including without limitation
 * the rights to use, copy, modify, merge, publish, distribute, sublicense,
 * and/or sell copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included
 * in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
 * OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
 * THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 * DEALINGS IN THE SOFTWARE.
 ****************************************************************************/
#include "kmlvector.h"
#include "kmlnode.h"
#include "cpl_conv.h"
// std
#include <string>

KMLVector::~KMLVector()
{
}

bool KMLVector::isLeaf(std::string const& sIn) const
{
    if( sIn.compare("name") == 0
        || sIn.compare("coordinates") == 0
        || sIn.compare("altitudeMode") == 0
        || sIn.compare("description") == 0 )
    {
        return true;
    }
    return false;
}

// Container - FeatureContainer - Feature

bool KMLVector::isContainer(std::string const& sIn) const
{
    if( sIn.compare("Folder") == 0
        || sIn.compare("Document") == 0
        || sIn.compare("kml") == 0 )
    {
        return true;
    }
    return false;
}

bool KMLVector::isFeatureContainer(std::string const& sIn) const
{
    if( sIn.compare("MultiGeometry") == 0
        || sIn.compare("Placemark") == 0 )
    {
        return true;
    }
    return false;
}

bool KMLVector::isFeature(std::string const& sIn) const
{
    if( sIn.compare("Polygon") == 0
        || sIn.compare("LineString") == 0
        || sIn.compare("Point") == 0 )
    {
        return true;
    }
    return false;
}

bool KMLVector::isRest(std::string const& sIn) const
{
    if( sIn.compare("outerBoundaryIs") == 0
        || sIn.compare("innerBoundaryIs") == 0
        || sIn.compare("LinearRing") == 0 )
    {
        return true;
    }
    return false;
}

void KMLVector::findLayers(KMLNode* poNode)
{
    bool bEmpty = true;

    // Start with the trunk
    if( NULL == poNode )
    {
        nNumLayers_ = 0;
        poNode = poTrunk_;
    }

    if( isFeature(poNode->getName())
        || isFeatureContainer(poNode->getName())
        || ( isRest(poNode->getName())
             && poNode->getName().compare("kml") != 0 ) )
    {
        return;
    }
    else if( isContainer(poNode->getName()) )
    {
        for( int z = 0; z < (int) poNode->countChildren(); z++ )
        {
            if( isContainer(poNode->getChild(z)->getName()) )
            {
                findLayers(poNode->getChild(z));
            }
            else if( isFeatureContainer(poNode->getChild(z)->getName()) )
            {
                bEmpty = false;
            }
        }

        if(bEmpty)
        {
            return;
        }
        
        Nodetype nodeType = poNode->getType();
        if( isFeature(Nodetype2String(nodeType)) ||
            nodeType == Mixed ||
            nodeType == MultiGeometry || nodeType == MultiPoint ||
            nodeType == MultiLineString || nodeType == MultiPolygon)
        {
            poNode->setLayerNumber(nNumLayers_++);
        }
        else
        {
            CPLDebug( "KML", "We have a strange type here for node %s: %s",
                      poNode->getName().c_str(), Nodetype2String(poNode->getType()).c_str() );
        }
    }
    else
    {
        CPLDebug("KML", "There is something wrong!  Define KML_DEBUG to see details");
        if( CPLGetConfigOption("KML_DEBUG",NULL) != NULL )
            print();
    }
}

