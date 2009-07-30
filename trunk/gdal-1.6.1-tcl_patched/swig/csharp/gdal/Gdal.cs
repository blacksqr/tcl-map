/* ----------------------------------------------------------------------------
 * This file was automatically generated by SWIG (http://www.swig.org).
 * Version 1.3.36
 *
 * Do not make changes to this file unless you know what you are doing--modify
 * the SWIG interface file instead.
 * ----------------------------------------------------------------------------- */

namespace OSGeo.GDAL {

using System;
using System.Runtime.InteropServices;

public class Gdal {

  internal class GdalObject : IDisposable {
	public virtual void Dispose() {
      
    }
  }
  internal static GdalObject theGdalObject = new GdalObject();
  protected static object ThisOwn_true() { return null; }
  protected static object ThisOwn_false() { return theGdalObject; }

  public static void UseExceptions() {
    GdalPINVOKE.UseExceptions();
  }

  public static void DontUseExceptions() {
    GdalPINVOKE.DontUseExceptions();
  }

  internal static void StringListDestroy(IntPtr buffer_ptr) {
    GdalPINVOKE.StringListDestroy(buffer_ptr);
    if (GdalPINVOKE.SWIGPendingException.Pending) throw GdalPINVOKE.SWIGPendingException.Retrieve();
  }

public delegate int GDALProgressFuncDelegate(double Complete, IntPtr Message, IntPtr Data);

  public static int GCPsToGeoTransform(GCP[] pGCPs, double[] argout, int bApproxOK) {
    int ret = 0;
    if (pGCPs != null && pGCPs.Length > 0)
     {
         IntPtr cPtr = __AllocCArray_GDAL_GCP(pGCPs.Length);
         if (cPtr == IntPtr.Zero)
            throw new ApplicationException("Error allocating CArray with __AllocCArray_GDAL_GCP");
            
         try {   
             for (int i=0; i < pGCPs.Length; i++)
                __WriteCArrayItem_GDAL_GCP(cPtr, i, pGCPs[i]);
             
             ret = GCPsToGeoTransform(pGCPs.Length, cPtr, argout, bApproxOK);
         }
         finally
         {
            __FreeCArray_GDAL_GCP(cPtr);
         }
     }
     return ret;
   }

  public static void Debug(string msg_class, string message) {
    GdalPINVOKE.Debug(msg_class, message);
    if (GdalPINVOKE.SWIGPendingException.Pending) throw GdalPINVOKE.SWIGPendingException.Retrieve();
  }

  public static void Error(CPLErr msg_class, int err_code, string msg) {
    GdalPINVOKE.Error((int)msg_class, err_code, msg);
    if (GdalPINVOKE.SWIGPendingException.Pending) throw GdalPINVOKE.SWIGPendingException.Retrieve();
  }

  public static CPLErr PushErrorHandler(string pszCallbackName) {
    CPLErr ret = (CPLErr)GdalPINVOKE.PushErrorHandler__SWIG_0(pszCallbackName);
    if (GdalPINVOKE.SWIGPendingException.Pending) throw GdalPINVOKE.SWIGPendingException.Retrieve();
    return ret;
  }

  public static void PushErrorHandler(SWIGTYPE_p_CPLErrorHandler arg0) {
    GdalPINVOKE.PushErrorHandler__SWIG_1(SWIGTYPE_p_CPLErrorHandler.getCPtr(arg0));
    if (GdalPINVOKE.SWIGPendingException.Pending) throw GdalPINVOKE.SWIGPendingException.Retrieve();
  }

  public static void PopErrorHandler() {
    GdalPINVOKE.PopErrorHandler();
    if (GdalPINVOKE.SWIGPendingException.Pending) throw GdalPINVOKE.SWIGPendingException.Retrieve();
  }

  public static void ErrorReset() {
    GdalPINVOKE.ErrorReset();
    if (GdalPINVOKE.SWIGPendingException.Pending) throw GdalPINVOKE.SWIGPendingException.Retrieve();
  }

  public static string EscapeString(int len, string bin_string, int scheme) {
    string ret = GdalPINVOKE.EscapeString(len, bin_string, scheme);
    if (GdalPINVOKE.SWIGPendingException.Pending) throw GdalPINVOKE.SWIGPendingException.Retrieve();
    return ret;
  }

  public static int GetLastErrorNo() {
    int ret = GdalPINVOKE.GetLastErrorNo();
    if (GdalPINVOKE.SWIGPendingException.Pending) throw GdalPINVOKE.SWIGPendingException.Retrieve();
    return ret;
  }

  public static CPLErr GetLastErrorType() {
    CPLErr ret = (CPLErr)GdalPINVOKE.GetLastErrorType();
    if (GdalPINVOKE.SWIGPendingException.Pending) throw GdalPINVOKE.SWIGPendingException.Retrieve();
    return ret;
  }

  public static string GetLastErrorMsg() {
    string ret = GdalPINVOKE.GetLastErrorMsg();
    if (GdalPINVOKE.SWIGPendingException.Pending) throw GdalPINVOKE.SWIGPendingException.Retrieve();
    return ret;
  }

  public static void PushFinderLocation(string arg0) {
    GdalPINVOKE.PushFinderLocation(arg0);
    if (GdalPINVOKE.SWIGPendingException.Pending) throw GdalPINVOKE.SWIGPendingException.Retrieve();
  }

  public static void PopFinderLocation() {
    GdalPINVOKE.PopFinderLocation();
    if (GdalPINVOKE.SWIGPendingException.Pending) throw GdalPINVOKE.SWIGPendingException.Retrieve();
  }

  public static void FinderClean() {
    GdalPINVOKE.FinderClean();
    if (GdalPINVOKE.SWIGPendingException.Pending) throw GdalPINVOKE.SWIGPendingException.Retrieve();
  }

  public static string FindFile(string arg0, string arg1) {
    string ret = GdalPINVOKE.FindFile(arg0, arg1);
    if (GdalPINVOKE.SWIGPendingException.Pending) throw GdalPINVOKE.SWIGPendingException.Retrieve();
    return ret;
  }

  public static string[] ReadDir(string arg0) {
        /* %typemap(csout) char**options */
        IntPtr cPtr = GdalPINVOKE.ReadDir(arg0);
        IntPtr objPtr;
        int count = 0;
        if (cPtr != IntPtr.Zero) {
            while (Marshal.ReadIntPtr(cPtr, count*IntPtr.Size) != IntPtr.Zero)
                ++count;
        }
        string[] ret = new string[count];
        if (count > 0) {       
	        for(int cx = 0; cx < count; cx++) {
                objPtr = System.Runtime.InteropServices.Marshal.ReadIntPtr(cPtr, cx * System.Runtime.InteropServices.Marshal.SizeOf(typeof(IntPtr)));
                ret[cx]= (objPtr == IntPtr.Zero) ? null : System.Runtime.InteropServices.Marshal.PtrToStringAnsi(objPtr);
            }
        }
        
    if (GdalPINVOKE.SWIGPendingException.Pending) throw GdalPINVOKE.SWIGPendingException.Retrieve();
        return ret;
}

  public static void SetConfigOption(string arg0, string arg1) {
    GdalPINVOKE.SetConfigOption(arg0, arg1);
    if (GdalPINVOKE.SWIGPendingException.Pending) throw GdalPINVOKE.SWIGPendingException.Retrieve();
  }

  public static string GetConfigOption(string arg0, string arg1) {
    string ret = GdalPINVOKE.GetConfigOption(arg0, arg1);
    if (GdalPINVOKE.SWIGPendingException.Pending) throw GdalPINVOKE.SWIGPendingException.Retrieve();
    return ret;
  }

  public static string CPLBinaryToHex(int nBytes, IntPtr pabyData) {
    string ret = GdalPINVOKE.CPLBinaryToHex(nBytes, pabyData);
    if (GdalPINVOKE.SWIGPendingException.Pending) throw GdalPINVOKE.SWIGPendingException.Retrieve();
    return ret;
  }

  public static IntPtr CPLHexToBinary(string pszHex, out int pnBytes) {
      IntPtr ret = GdalPINVOKE.CPLHexToBinary(pszHex, out pnBytes);
    if (GdalPINVOKE.SWIGPendingException.Pending) throw GdalPINVOKE.SWIGPendingException.Retrieve();
      return ret;
}

  public static double GDAL_GCP_GCPX_get(GCP h) {
    double ret = GdalPINVOKE.GDAL_GCP_GCPX_get(GCP.getCPtr(h));
    if (GdalPINVOKE.SWIGPendingException.Pending) throw GdalPINVOKE.SWIGPendingException.Retrieve();
    return ret;
  }

  public static void GDAL_GCP_GCPX_set(GCP h, double val) {
    GdalPINVOKE.GDAL_GCP_GCPX_set(GCP.getCPtr(h), val);
    if (GdalPINVOKE.SWIGPendingException.Pending) throw GdalPINVOKE.SWIGPendingException.Retrieve();
  }

  public static double GDAL_GCP_GCPY_get(GCP h) {
    double ret = GdalPINVOKE.GDAL_GCP_GCPY_get(GCP.getCPtr(h));
    if (GdalPINVOKE.SWIGPendingException.Pending) throw GdalPINVOKE.SWIGPendingException.Retrieve();
    return ret;
  }

  public static void GDAL_GCP_GCPY_set(GCP h, double val) {
    GdalPINVOKE.GDAL_GCP_GCPY_set(GCP.getCPtr(h), val);
    if (GdalPINVOKE.SWIGPendingException.Pending) throw GdalPINVOKE.SWIGPendingException.Retrieve();
  }

  public static double GDAL_GCP_GCPZ_get(GCP h) {
    double ret = GdalPINVOKE.GDAL_GCP_GCPZ_get(GCP.getCPtr(h));
    if (GdalPINVOKE.SWIGPendingException.Pending) throw GdalPINVOKE.SWIGPendingException.Retrieve();
    return ret;
  }

  public static void GDAL_GCP_GCPZ_set(GCP h, double val) {
    GdalPINVOKE.GDAL_GCP_GCPZ_set(GCP.getCPtr(h), val);
    if (GdalPINVOKE.SWIGPendingException.Pending) throw GdalPINVOKE.SWIGPendingException.Retrieve();
  }

  public static double GDAL_GCP_GCPPixel_get(GCP h) {
    double ret = GdalPINVOKE.GDAL_GCP_GCPPixel_get(GCP.getCPtr(h));
    if (GdalPINVOKE.SWIGPendingException.Pending) throw GdalPINVOKE.SWIGPendingException.Retrieve();
    return ret;
  }

  public static void GDAL_GCP_GCPPixel_set(GCP h, double val) {
    GdalPINVOKE.GDAL_GCP_GCPPixel_set(GCP.getCPtr(h), val);
    if (GdalPINVOKE.SWIGPendingException.Pending) throw GdalPINVOKE.SWIGPendingException.Retrieve();
  }

  public static double GDAL_GCP_GCPLine_get(GCP h) {
    double ret = GdalPINVOKE.GDAL_GCP_GCPLine_get(GCP.getCPtr(h));
    if (GdalPINVOKE.SWIGPendingException.Pending) throw GdalPINVOKE.SWIGPendingException.Retrieve();
    return ret;
  }

  public static void GDAL_GCP_GCPLine_set(GCP h, double val) {
    GdalPINVOKE.GDAL_GCP_GCPLine_set(GCP.getCPtr(h), val);
    if (GdalPINVOKE.SWIGPendingException.Pending) throw GdalPINVOKE.SWIGPendingException.Retrieve();
  }

  public static string GDAL_GCP_Info_get(GCP h) {
    string ret = GdalPINVOKE.GDAL_GCP_Info_get(GCP.getCPtr(h));
    if (GdalPINVOKE.SWIGPendingException.Pending) throw GdalPINVOKE.SWIGPendingException.Retrieve();
    return ret;
  }

  public static void GDAL_GCP_Info_set(GCP h, string val) {
    GdalPINVOKE.GDAL_GCP_Info_set(GCP.getCPtr(h), val);
    if (GdalPINVOKE.SWIGPendingException.Pending) throw GdalPINVOKE.SWIGPendingException.Retrieve();
  }

  public static string GDAL_GCP_Id_get(GCP h) {
    string ret = GdalPINVOKE.GDAL_GCP_Id_get(GCP.getCPtr(h));
    if (GdalPINVOKE.SWIGPendingException.Pending) throw GdalPINVOKE.SWIGPendingException.Retrieve();
    return ret;
  }

  public static void GDAL_GCP_Id_set(GCP h, string val) {
    GdalPINVOKE.GDAL_GCP_Id_set(GCP.getCPtr(h), val);
    if (GdalPINVOKE.SWIGPendingException.Pending) throw GdalPINVOKE.SWIGPendingException.Retrieve();
  }

  public static double GDAL_GCP_get_GCPX(GCP h) {
    double ret = GdalPINVOKE.GDAL_GCP_get_GCPX(GCP.getCPtr(h));
    if (GdalPINVOKE.SWIGPendingException.Pending) throw GdalPINVOKE.SWIGPendingException.Retrieve();
    return ret;
  }

  public static void GDAL_GCP_set_GCPX(GCP h, double val) {
    GdalPINVOKE.GDAL_GCP_set_GCPX(GCP.getCPtr(h), val);
    if (GdalPINVOKE.SWIGPendingException.Pending) throw GdalPINVOKE.SWIGPendingException.Retrieve();
  }

  public static double GDAL_GCP_get_GCPY(GCP h) {
    double ret = GdalPINVOKE.GDAL_GCP_get_GCPY(GCP.getCPtr(h));
    if (GdalPINVOKE.SWIGPendingException.Pending) throw GdalPINVOKE.SWIGPendingException.Retrieve();
    return ret;
  }

  public static void GDAL_GCP_set_GCPY(GCP h, double val) {
    GdalPINVOKE.GDAL_GCP_set_GCPY(GCP.getCPtr(h), val);
    if (GdalPINVOKE.SWIGPendingException.Pending) throw GdalPINVOKE.SWIGPendingException.Retrieve();
  }

  public static double GDAL_GCP_get_GCPZ(GCP h) {
    double ret = GdalPINVOKE.GDAL_GCP_get_GCPZ(GCP.getCPtr(h));
    if (GdalPINVOKE.SWIGPendingException.Pending) throw GdalPINVOKE.SWIGPendingException.Retrieve();
    return ret;
  }

  public static void GDAL_GCP_set_GCPZ(GCP h, double val) {
    GdalPINVOKE.GDAL_GCP_set_GCPZ(GCP.getCPtr(h), val);
    if (GdalPINVOKE.SWIGPendingException.Pending) throw GdalPINVOKE.SWIGPendingException.Retrieve();
  }

  public static double GDAL_GCP_get_GCPPixel(GCP h) {
    double ret = GdalPINVOKE.GDAL_GCP_get_GCPPixel(GCP.getCPtr(h));
    if (GdalPINVOKE.SWIGPendingException.Pending) throw GdalPINVOKE.SWIGPendingException.Retrieve();
    return ret;
  }

  public static void GDAL_GCP_set_GCPPixel(GCP h, double val) {
    GdalPINVOKE.GDAL_GCP_set_GCPPixel(GCP.getCPtr(h), val);
    if (GdalPINVOKE.SWIGPendingException.Pending) throw GdalPINVOKE.SWIGPendingException.Retrieve();
  }

  public static double GDAL_GCP_get_GCPLine(GCP h) {
    double ret = GdalPINVOKE.GDAL_GCP_get_GCPLine(GCP.getCPtr(h));
    if (GdalPINVOKE.SWIGPendingException.Pending) throw GdalPINVOKE.SWIGPendingException.Retrieve();
    return ret;
  }

  public static void GDAL_GCP_set_GCPLine(GCP h, double val) {
    GdalPINVOKE.GDAL_GCP_set_GCPLine(GCP.getCPtr(h), val);
    if (GdalPINVOKE.SWIGPendingException.Pending) throw GdalPINVOKE.SWIGPendingException.Retrieve();
  }

  public static string GDAL_GCP_get_Info(GCP h) {
    string ret = GdalPINVOKE.GDAL_GCP_get_Info(GCP.getCPtr(h));
    if (GdalPINVOKE.SWIGPendingException.Pending) throw GdalPINVOKE.SWIGPendingException.Retrieve();
    return ret;
  }

  public static void GDAL_GCP_set_Info(GCP h, string val) {
    GdalPINVOKE.GDAL_GCP_set_Info(GCP.getCPtr(h), val);
    if (GdalPINVOKE.SWIGPendingException.Pending) throw GdalPINVOKE.SWIGPendingException.Retrieve();
  }

  public static string GDAL_GCP_get_Id(GCP h) {
    string ret = GdalPINVOKE.GDAL_GCP_get_Id(GCP.getCPtr(h));
    if (GdalPINVOKE.SWIGPendingException.Pending) throw GdalPINVOKE.SWIGPendingException.Retrieve();
    return ret;
  }

  public static void GDAL_GCP_set_Id(GCP h, string val) {
    GdalPINVOKE.GDAL_GCP_set_Id(GCP.getCPtr(h), val);
    if (GdalPINVOKE.SWIGPendingException.Pending) throw GdalPINVOKE.SWIGPendingException.Retrieve();
  }

  private static int GCPsToGeoTransform(int nGCPs, IntPtr pGCPs, double[] argout, int bApproxOK) {
    int res = GdalPINVOKE.GCPsToGeoTransform(nGCPs, pGCPs, argout, bApproxOK);
    if (GdalPINVOKE.SWIGPendingException.Pending) throw GdalPINVOKE.SWIGPendingException.Retrieve();
    return res;
}

  public static int ComputeMedianCutPCT(Band red, Band green, Band blue, int num_colors, ColorTable colors, Gdal.GDALProgressFuncDelegate callback, string callback_data) {
    int ret = GdalPINVOKE.ComputeMedianCutPCT(Band.getCPtr(red), Band.getCPtr(green), Band.getCPtr(blue), num_colors, ColorTable.getCPtr(colors), callback, callback_data);
    if (GdalPINVOKE.SWIGPendingException.Pending) throw GdalPINVOKE.SWIGPendingException.Retrieve();
    return ret;
  }

  public static int DitherRGB2PCT(Band red, Band green, Band blue, Band target, ColorTable colors, Gdal.GDALProgressFuncDelegate callback, string callback_data) {
    int ret = GdalPINVOKE.DitherRGB2PCT(Band.getCPtr(red), Band.getCPtr(green), Band.getCPtr(blue), Band.getCPtr(target), ColorTable.getCPtr(colors), callback, callback_data);
    if (GdalPINVOKE.SWIGPendingException.Pending) throw GdalPINVOKE.SWIGPendingException.Retrieve();
    return ret;
  }

  public static CPLErr ReprojectImage(Dataset src_ds, Dataset dst_ds, string src_wkt, string dst_wkt, ResampleAlg eResampleAlg, double WarpMemoryLimit, double maxerror, Gdal.GDALProgressFuncDelegate callback, string callback_data) {
    CPLErr ret = (CPLErr)GdalPINVOKE.ReprojectImage(Dataset.getCPtr(src_ds), Dataset.getCPtr(dst_ds), src_wkt, dst_wkt, (int)eResampleAlg, WarpMemoryLimit, maxerror, callback, callback_data);
    if (GdalPINVOKE.SWIGPendingException.Pending) throw GdalPINVOKE.SWIGPendingException.Retrieve();
    return ret;
  }

  public static int ComputeProximity(Band srcBand, Band proximityBand, string[] options, Gdal.GDALProgressFuncDelegate callback, string callback_data) {
    int ret = GdalPINVOKE.ComputeProximity(Band.getCPtr(srcBand), Band.getCPtr(proximityBand), (options != null)? new GdalPINVOKE.StringListMarshal(options)._ar : null, callback, callback_data);
    if (GdalPINVOKE.SWIGPendingException.Pending) throw GdalPINVOKE.SWIGPendingException.Retrieve();
    return ret;
  }

  public static int RasterizeLayer(Dataset dataset, int bands, SWIGTYPE_p_int band_list, OSGeo.OGR.Layer layer, SWIGTYPE_p_void pfnTransformer, SWIGTYPE_p_void pTransformArg, int burn_values, SWIGTYPE_p_double burn_values_list, string[] options, Gdal.GDALProgressFuncDelegate callback, string callback_data) {
    int ret = GdalPINVOKE.RasterizeLayer(Dataset.getCPtr(dataset), bands, SWIGTYPE_p_int.getCPtr(band_list), OSGeo.OGR.Layer.getCPtr(layer), SWIGTYPE_p_void.getCPtr(pfnTransformer), SWIGTYPE_p_void.getCPtr(pTransformArg), burn_values, SWIGTYPE_p_double.getCPtr(burn_values_list), (options != null)? new GdalPINVOKE.StringListMarshal(options)._ar : null, callback, callback_data);
    if (GdalPINVOKE.SWIGPendingException.Pending) throw GdalPINVOKE.SWIGPendingException.Retrieve();
    return ret;
  }

  public static int Polygonize(Band srcBand, Band maskBand, OSGeo.OGR.Layer outLayer, int iPixValField, string[] options, Gdal.GDALProgressFuncDelegate callback, string callback_data) {
    int ret = GdalPINVOKE.Polygonize(Band.getCPtr(srcBand), Band.getCPtr(maskBand), OSGeo.OGR.Layer.getCPtr(outLayer), iPixValField, (options != null)? new GdalPINVOKE.StringListMarshal(options)._ar : null, callback, callback_data);
    if (GdalPINVOKE.SWIGPendingException.Pending) throw GdalPINVOKE.SWIGPendingException.Retrieve();
    return ret;
  }

  public static int SieveFilter(Band srcBand, Band maskBand, Band dstBand, int threshold, int connectedness, string[] options, Gdal.GDALProgressFuncDelegate callback, string callback_data) {
    int ret = GdalPINVOKE.SieveFilter(Band.getCPtr(srcBand), Band.getCPtr(maskBand), Band.getCPtr(dstBand), threshold, connectedness, (options != null)? new GdalPINVOKE.StringListMarshal(options)._ar : null, callback, callback_data);
    if (GdalPINVOKE.SWIGPendingException.Pending) throw GdalPINVOKE.SWIGPendingException.Retrieve();
    return ret;
  }

  public static int RegenerateOverviews(Band srcBand, int overviewBandCount, SWIGTYPE_p_p_GDALRasterBandShadow overviewBands, string resampling, Gdal.GDALProgressFuncDelegate callback, string callback_data) {
    int ret = GdalPINVOKE.RegenerateOverviews(Band.getCPtr(srcBand), overviewBandCount, SWIGTYPE_p_p_GDALRasterBandShadow.getCPtr(overviewBands), resampling, callback, callback_data);
    if (GdalPINVOKE.SWIGPendingException.Pending) throw GdalPINVOKE.SWIGPendingException.Retrieve();
    return ret;
  }

  public static int RegenerateOverview(Band srcBand, Band overviewBand, string resampling, Gdal.GDALProgressFuncDelegate callback, string callback_data) {
    int ret = GdalPINVOKE.RegenerateOverview(Band.getCPtr(srcBand), Band.getCPtr(overviewBand), resampling, callback, callback_data);
    if (GdalPINVOKE.SWIGPendingException.Pending) throw GdalPINVOKE.SWIGPendingException.Retrieve();
    return ret;
  }

  public static Dataset AutoCreateWarpedVRT(Dataset src_ds, string src_wkt, string dst_wkt, ResampleAlg eResampleAlg, double maxerror) {
    IntPtr cPtr = GdalPINVOKE.AutoCreateWarpedVRT(Dataset.getCPtr(src_ds), src_wkt, dst_wkt, (int)eResampleAlg, maxerror);
    Dataset ret = (cPtr == IntPtr.Zero) ? null : new Dataset(cPtr, true, ThisOwn_true());
    if (GdalPINVOKE.SWIGPendingException.Pending) throw GdalPINVOKE.SWIGPendingException.Retrieve();
    return ret;
  }

  public static string VersionInfo(string request) {
    string ret = GdalPINVOKE.VersionInfo(request);
    if (GdalPINVOKE.SWIGPendingException.Pending) throw GdalPINVOKE.SWIGPendingException.Retrieve();
    return ret;
  }

  public static void AllRegister() {
    GdalPINVOKE.AllRegister();
    if (GdalPINVOKE.SWIGPendingException.Pending) throw GdalPINVOKE.SWIGPendingException.Retrieve();
  }

  public static void GDALDestroyDriverManager() {
    GdalPINVOKE.GDALDestroyDriverManager();
    if (GdalPINVOKE.SWIGPendingException.Pending) throw GdalPINVOKE.SWIGPendingException.Retrieve();
  }

  public static int GetCacheMax() {
    int ret = GdalPINVOKE.GetCacheMax();
    if (GdalPINVOKE.SWIGPendingException.Pending) throw GdalPINVOKE.SWIGPendingException.Retrieve();
    return ret;
  }

  public static void SetCacheMax(int nBytes) {
    GdalPINVOKE.SetCacheMax(nBytes);
    if (GdalPINVOKE.SWIGPendingException.Pending) throw GdalPINVOKE.SWIGPendingException.Retrieve();
  }

  public static int GetCacheUsed() {
    int ret = GdalPINVOKE.GetCacheUsed();
    if (GdalPINVOKE.SWIGPendingException.Pending) throw GdalPINVOKE.SWIGPendingException.Retrieve();
    return ret;
  }

  public static int GetDataTypeSize(DataType arg0) {
    int ret = GdalPINVOKE.GetDataTypeSize((int)arg0);
    if (GdalPINVOKE.SWIGPendingException.Pending) throw GdalPINVOKE.SWIGPendingException.Retrieve();
    return ret;
  }

  public static int DataTypeIsComplex(DataType arg0) {
    int ret = GdalPINVOKE.DataTypeIsComplex((int)arg0);
    if (GdalPINVOKE.SWIGPendingException.Pending) throw GdalPINVOKE.SWIGPendingException.Retrieve();
    return ret;
  }

  public static string GetDataTypeName(DataType arg0) {
    string ret = GdalPINVOKE.GetDataTypeName((int)arg0);
    if (GdalPINVOKE.SWIGPendingException.Pending) throw GdalPINVOKE.SWIGPendingException.Retrieve();
    return ret;
  }

  public static DataType GetDataTypeByName(string arg0) {
    DataType ret = (DataType)GdalPINVOKE.GetDataTypeByName(arg0);
    if (GdalPINVOKE.SWIGPendingException.Pending) throw GdalPINVOKE.SWIGPendingException.Retrieve();
    return ret;
  }

  public static string GetColorInterpretationName(ColorInterp arg0) {
    string ret = GdalPINVOKE.GetColorInterpretationName((int)arg0);
    if (GdalPINVOKE.SWIGPendingException.Pending) throw GdalPINVOKE.SWIGPendingException.Retrieve();
    return ret;
  }

  public static string GetPaletteInterpretationName(PaletteInterp arg0) {
    string ret = GdalPINVOKE.GetPaletteInterpretationName((int)arg0);
    if (GdalPINVOKE.SWIGPendingException.Pending) throw GdalPINVOKE.SWIGPendingException.Retrieve();
    return ret;
  }

  public static string DecToDMS(double arg0, string arg1, int arg2) {
    string ret = GdalPINVOKE.DecToDMS(arg0, arg1, arg2);
    if (GdalPINVOKE.SWIGPendingException.Pending) throw GdalPINVOKE.SWIGPendingException.Retrieve();
    return ret;
  }

  public static double PackedDMSToDec(double arg0) {
    double ret = GdalPINVOKE.PackedDMSToDec(arg0);
    if (GdalPINVOKE.SWIGPendingException.Pending) throw GdalPINVOKE.SWIGPendingException.Retrieve();
    return ret;
  }

  public static double DecToPackedDMS(double arg0) {
    double ret = GdalPINVOKE.DecToPackedDMS(arg0);
    if (GdalPINVOKE.SWIGPendingException.Pending) throw GdalPINVOKE.SWIGPendingException.Retrieve();
    return ret;
  }

  public static XMLNode ParseXMLString(string arg0) {
    IntPtr cPtr = GdalPINVOKE.ParseXMLString(arg0);
    XMLNode ret = (cPtr == IntPtr.Zero) ? null : new XMLNode(cPtr, true, ThisOwn_true());
    if (GdalPINVOKE.SWIGPendingException.Pending) throw GdalPINVOKE.SWIGPendingException.Retrieve();
    return ret;
  }

  public static string SerializeXMLTree(XMLNode xmlnode) {
    string ret = GdalPINVOKE.SerializeXMLTree(XMLNode.getCPtr(xmlnode));
    if (GdalPINVOKE.SWIGPendingException.Pending) throw GdalPINVOKE.SWIGPendingException.Retrieve();
    return ret;
  }

  public static int GetDriverCount() {
    int ret = GdalPINVOKE.GetDriverCount();
    if (GdalPINVOKE.SWIGPendingException.Pending) throw GdalPINVOKE.SWIGPendingException.Retrieve();
    return ret;
  }

  public static Driver GetDriverByName(string name) {
    IntPtr cPtr = GdalPINVOKE.GetDriverByName(name);
    Driver ret = (cPtr == IntPtr.Zero) ? null : new Driver(cPtr, false, ThisOwn_false());
    if (GdalPINVOKE.SWIGPendingException.Pending) throw GdalPINVOKE.SWIGPendingException.Retrieve();
    return ret;
  }

  public static Driver GetDriver(int i) {
    IntPtr cPtr = GdalPINVOKE.GetDriver(i);
    Driver ret = (cPtr == IntPtr.Zero) ? null : new Driver(cPtr, false, ThisOwn_false());
    if (GdalPINVOKE.SWIGPendingException.Pending) throw GdalPINVOKE.SWIGPendingException.Retrieve();
    return ret;
  }

  public static Dataset Open(string name, Access eAccess) {
    IntPtr cPtr = GdalPINVOKE.Open(name, (int)eAccess);
    Dataset ret = (cPtr == IntPtr.Zero) ? null : new Dataset(cPtr, true, ThisOwn_true());
    if (GdalPINVOKE.SWIGPendingException.Pending) throw GdalPINVOKE.SWIGPendingException.Retrieve();
    return ret;
  }

  public static Dataset OpenShared(string name, Access eAccess) {
    IntPtr cPtr = GdalPINVOKE.OpenShared(name, (int)eAccess);
    Dataset ret = (cPtr == IntPtr.Zero) ? null : new Dataset(cPtr, true, ThisOwn_true());
    if (GdalPINVOKE.SWIGPendingException.Pending) throw GdalPINVOKE.SWIGPendingException.Retrieve();
    return ret;
  }

  public static Driver IdentifyDriver(string pszDatasource, string[] papszSiblings) {
    IntPtr cPtr = GdalPINVOKE.IdentifyDriver(pszDatasource, (papszSiblings != null)? new GdalPINVOKE.StringListMarshal(papszSiblings)._ar : null);
    Driver ret = (cPtr == IntPtr.Zero) ? null : new Driver(cPtr, false, ThisOwn_false());
    if (GdalPINVOKE.SWIGPendingException.Pending) throw GdalPINVOKE.SWIGPendingException.Retrieve();
    return ret;
  }

  public static string[] GeneralCmdLineProcessor(string[] papszArgv, int nOptions) {
        /* %typemap(csout) char**options */
        IntPtr cPtr = GdalPINVOKE.GeneralCmdLineProcessor((papszArgv != null)? new GdalPINVOKE.StringListMarshal(papszArgv)._ar : null, nOptions);
        IntPtr objPtr;
        int count = 0;
        if (cPtr != IntPtr.Zero) {
            while (Marshal.ReadIntPtr(cPtr, count*IntPtr.Size) != IntPtr.Zero)
                ++count;
        }
        string[] ret = new string[count];
        if (count > 0) {       
	        for(int cx = 0; cx < count; cx++) {
                objPtr = System.Runtime.InteropServices.Marshal.ReadIntPtr(cPtr, cx * System.Runtime.InteropServices.Marshal.SizeOf(typeof(IntPtr)));
                ret[cx]= (objPtr == IntPtr.Zero) ? null : System.Runtime.InteropServices.Marshal.PtrToStringAnsi(objPtr);
            }
        }
        
    if (GdalPINVOKE.SWIGPendingException.Pending) throw GdalPINVOKE.SWIGPendingException.Retrieve();
        return ret;
}

  internal static void __WriteCArrayItem_GDAL_GCP(IntPtr carray, int index, GCP value) {
    GdalPINVOKE.__WriteCArrayItem_GDAL_GCP(carray, index, GCP.getCPtr(value));
    if (GdalPINVOKE.SWIGPendingException.Pending) throw GdalPINVOKE.SWIGPendingException.Retrieve();
  }

  internal static GCP __ReadCArrayItem_GDAL_GCP(IntPtr carray, int index) {
    IntPtr cPtr = GdalPINVOKE.__ReadCArrayItem_GDAL_GCP(carray, index);
    GCP ret = (cPtr == IntPtr.Zero) ? null : new GCP(cPtr, false, ThisOwn_false());
    if (GdalPINVOKE.SWIGPendingException.Pending) throw GdalPINVOKE.SWIGPendingException.Retrieve();
    return ret;
  }

  internal static IntPtr __AllocCArray_GDAL_GCP(int size) {
      IntPtr ret = GdalPINVOKE.__AllocCArray_GDAL_GCP(size);
    if (GdalPINVOKE.SWIGPendingException.Pending) throw GdalPINVOKE.SWIGPendingException.Retrieve();
      return ret;
}

  internal static void __FreeCArray_GDAL_GCP(IntPtr carray) {
    GdalPINVOKE.__FreeCArray_GDAL_GCP(carray);
    if (GdalPINVOKE.SWIGPendingException.Pending) throw GdalPINVOKE.SWIGPendingException.Retrieve();
  }

}

}
