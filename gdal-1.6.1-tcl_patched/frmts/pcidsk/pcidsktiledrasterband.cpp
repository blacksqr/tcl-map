/******************************************************************************
 * $Id: pcidsktiledrasterband.cpp 10645 2007-01-18 02:22:39Z warmerdam $
 *
 * Project:  PCIDSK Database File
 * Purpose:  Implementation of PCIDSKTiledRasterBand
 * Author:   Frank Warmerdam <warmerdam@pobox.com>
 *
 ******************************************************************************
 * Copyright (c) 2005, Frank Warmerdam <warmerdam@pobox.com>
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

#include "gdal_pcidsk.h"

CPL_CVSID("$Id: pcidsktiledrasterband.cpp 10645 2007-01-18 02:22:39Z warmerdam $");

/************************************************************************/
/*                           PCIDSKRasterBand()                         */
/************************************************************************/

PCIDSKTiledRasterBand::PCIDSKTiledRasterBand( PCIDSKDataset *poDS, 
                                              int nBand, int nImage )

{
    poPDS = poDS;
    this->poDS = poDS;

    this->nBand = nBand;
    this->nImage = nImage;

    nOverviewCount = 0;
    papoOverviews = NULL;

    nBlocks = 0;
    panBlockOffset = NULL;
    
    if( !BuildBlockMap() )
        return;

/* -------------------------------------------------------------------- */
/*      Load and parse image header.  This is the image header          */
/*      within the tiled image data.                                    */
/* -------------------------------------------------------------------- */
    char achBData[128];

    SysRead( 0, 128, achBData );
 
    nRasterXSize = (int) CPLScanLong(achBData + 0, 8);
    nRasterYSize = (int) CPLScanLong(achBData + 8, 8);
    nBlockXSize = (int) CPLScanLong(achBData + 16, 8);
    nBlockYSize = (int) CPLScanLong(achBData + 24, 8);
    
    eDataType = poPDS->PCIDSKTypeToGDAL( achBData + 32 );
}

/************************************************************************/
/*                       ~PCIDSKTiledRasterBand()                       */
/************************************************************************/

PCIDSKTiledRasterBand::~PCIDSKTiledRasterBand()
{
    FlushCache();

    int i;

    for( i = 0; i < nOverviewCount; i++ )
        delete papoOverviews[i];
    CPLFree( papoOverviews );

    CPLFree( panBlockOffset );
    CPLFree( panTileOffset );
    CPLFree( panTileSize );
}

/************************************************************************/
/*                           BuildBlockMap()                            */
/************************************************************************/

int PCIDSKTiledRasterBand::BuildBlockMap()

{
    nBlocks = 0;
    panBlockOffset = NULL;

    nTileCount = 0;
    panTileOffset = NULL;
    panTileSize = NULL;

/* -------------------------------------------------------------------- */
/*      Read the whole block map segment.                               */
/* -------------------------------------------------------------------- */
    int  nBMapSize;
    char *pachBMap;

    if( poPDS->nBlockMapSeg < 1 )
        return FALSE;

    nBMapSize = poPDS->panSegSize[poPDS->nBlockMapSeg-1];
    pachBMap = (char *) CPLCalloc(nBMapSize+1,1);
    
    if( !poPDS->SegRead( poPDS->nBlockMapSeg, 0, nBMapSize, pachBMap ) )
        return FALSE;
    
/* -------------------------------------------------------------------- */
/*      Parse the header.                                               */
/* -------------------------------------------------------------------- */
    int nMaxBlocks = (int) CPLScanLong(pachBMap + 18,8);

    if( !EQUALN(pachBMap,"VERSION",7) )
        return FALSE;

/* -------------------------------------------------------------------- */
/*      Build a "back link" map for this image's blocks.  We need       */
/*      this to positively identify the first block in the chain.       */
/* -------------------------------------------------------------------- */
    int *panBackLink;
    int i, nLastBlock = -1;

    panBackLink = (int *) CPLCalloc(sizeof(int),nMaxBlocks);
    for( i = 0; i < nMaxBlocks; i++ )
        panBackLink[i] = -1;

    for( i = 0; i < nMaxBlocks; i++ )
    {
        char *pachEntry = pachBMap + i * 28 + 512;
        int nThisImage = (int) CPLScanLong(pachEntry + 12,8);
        int nNextBlock = (int) CPLScanLong(pachEntry + 20,8);

        if( nThisImage != nImage )
            continue;

        if( nNextBlock == -1 )
            nLastBlock = i;
        else
            panBackLink[nNextBlock] = i;
    }
    
/* -------------------------------------------------------------------- */
/*      Track back through chain to identify the first entry (while     */
/*      counting).                                                      */
/* -------------------------------------------------------------------- */
    int iBlock = nLastBlock;

    nBlocks = 1;
    while( panBackLink[iBlock] != -1 )
    {
        nBlocks++;
        iBlock = panBackLink[iBlock];
    }

    CPLFree( panBackLink );
    panBlockOffset = (vsi_l_offset *) CPLMalloc(sizeof(vsi_l_offset)*nBlocks);

/* -------------------------------------------------------------------- */
/*      Process blocks, transforming to absolute offsets in the         */
/*      PCIDSK file.                                                    */
/* -------------------------------------------------------------------- */
    for( i = 0; i < nBlocks; i++ )
    {
        char *pachEntry = pachBMap + iBlock * 28 + 512;
        int nBDataSeg = CPLScanLong( pachEntry + 0, 4 );
        int nBDataBlock = CPLScanLong( pachEntry + 4, 8 );

        CPLAssert( poPDS->panSegType[nBDataSeg-1] == 182 );

        panBlockOffset[i] = 
            ((vsi_l_offset) nBDataBlock) * 8192
            + poPDS->panSegOffset[nBDataSeg-1] + 1024;

        iBlock = (int) CPLScanLong( pachEntry + 20, 8 );
    }            

    CPLFree( pachBMap );

    return TRUE;
}

/************************************************************************/
/*                            BuildTileMap()                            */
/************************************************************************/

int PCIDSKTiledRasterBand::BuildTileMap()

{
    if( nTileCount )
        return TRUE;

    int nBPR = (nRasterXSize + nBlockXSize - 1) / nBlockXSize;
    int nBPC = (nRasterYSize + nBlockYSize - 1) / nBlockYSize;

    nTileCount = nBPR * nBPC;
    panTileOffset = (vsi_l_offset *) 
        CPLCalloc(sizeof(vsi_l_offset),nTileCount);
    panTileSize = (int *) CPLCalloc(sizeof(int),nTileCount);

    char *pachTileInfo = (char *) CPLMalloc(20 * nTileCount);
    if( !SysRead( 128, 20 * nTileCount, pachTileInfo ) )
    {
        CPLFree( pachTileInfo );
        return FALSE;
    }

    for( int iTile = 0; iTile < nTileCount; iTile++ )
    {
        panTileOffset[iTile] = (vsi_l_offset)
            CPLScanUIntBig( pachTileInfo+12*iTile, 12 );
        panTileSize[iTile] = (int)
            CPLScanLong( pachTileInfo+12*nTileCount+8*iTile, 8 );
    }

    CPLFree( pachTileInfo );

    return TRUE;
}

/************************************************************************/
/*                             IReadBlock()                             */
/************************************************************************/

CPLErr PCIDSKTiledRasterBand::IReadBlock( int nBlockX, int nBlockY, 
                                          void *pData )

{
    int iTile;

    if( !BuildTileMap() )
        return CE_Failure;
    
    int nBPR = (nRasterXSize + nBlockXSize - 1) / nBlockXSize;

    iTile = nBlockX + nBlockY * nBPR;

    if( !SysRead( panTileOffset[iTile], panTileSize[iTile], pData ) )
        return CE_Failure;


/* -------------------------------------------------------------------- */
/*      PCIDSK multibyte data is always big endian.  Swap if needed.    */
/* -------------------------------------------------------------------- */
#ifdef CPL_LSB
    int   nWordSize = GDALGetDataTypeSize( eDataType ) / 8;
    GDALSwapWords( pData, nWordSize, nBlockXSize * nBlockYSize, nWordSize );
#endif

    return CE_None;
}

/************************************************************************/
/*                              SysRead()                               */
/************************************************************************/

int PCIDSKTiledRasterBand::SysRead( vsi_l_offset nOffset, 
                                    int nSize, 
                                    void *pData )

{
    int iReadSoFar = 0;

    while( iReadSoFar < nSize )
    {
        int iBlock;
        vsi_l_offset nNextOffset = nOffset + iReadSoFar;
        vsi_l_offset nRealOffset;
        int          nOffsetInBlock, nThisReadBytes;
        
        iBlock = (int) (nNextOffset >> 13);
        nOffsetInBlock = (nNextOffset & 0x1fff);

        nRealOffset = panBlockOffset[iBlock] + nOffsetInBlock;
        
        nThisReadBytes = MIN(nSize - iReadSoFar,8192 - nOffsetInBlock);
        
        if( VSIFSeekL( poPDS->fp, nRealOffset, SEEK_SET ) != 0 )
            return 0;

        if( VSIFReadL( ((char *) pData) + iReadSoFar, 1, nThisReadBytes,
                       poPDS->fp ) != (size_t) nThisReadBytes )
            return 0;

        iReadSoFar += nThisReadBytes;
    }

    return nSize;
}
