<%@ WebHandler Language="C#" Class="UploadHandler" %>

using System;
using System.Net;
using System.IO;
using System.Web;
using System.Linq;
using Newtonsoft.Json;
using System.Collections.Generic;
using System.Data;
using System.Xml;
using System.Reflection;
using NPOI.SS.UserModel;
using NPOI.XSSF.UserModel;
using NPOI.HSSF.UserModel;

public class UploadHandler : IHttpHandler
{
    public class Record
    {
        public string FBillNo { get; set; }
        public string FPayUser { get; set; }
        public string FInvCode { get; set; }
        public string FInvName { get; set; }
        public string FCustomer { get; set; }
        public string FCustCode { get; set; }
        public string FDeviceNo { get; set; }
        public string FAgent { get; set; }
        public string FAgentCode { get; set; }
        public string FAddress { get; set; }
        public string FAgentType { get; set; }
        public string FSpecification { get; set; }
        public string FCoupon { get; set; }
        public string FAmount { get; set; }
        public string FSellAmount { get; set; }
        public string FStaffReward { get; set; }
        public string FPersonalAgent { get; set; }
        public string FPartner { get; set; }
        public string FAdditionalPartner { get; set; }
        public string FOrderStatus { get; set; }
        public string FOrderDate { get; set; }
        public string FMemo { get; set; }
        public string FQuantity { get; set; }
        public bool FIsValid { get; set; }
        public int FErrorCount { get; set; }
        public string FErrorMsg { get; set; }
    }

    public class Customer
    {
        public string code { get; set; }
        public string name { get; set; }

    }

    public class Inv
    {
        public string code { get; set; }
        public string name { get; set; }
        public string specification { get; set; }

    }

    public class BillRecord
    {
        public string detailmemo { get; set; }
    }


    public class SaleDelivery
    {
        /// <summary>
        /// 当前登录用户编码
        /// </summary>
        public string FUserCode { get; set; }


        /// <summary>
        /// 当前登录用户名称
        /// </summary>
        public string FUserName { get; set; }

        /// <summary>
        /// 制单日期
        /// </summary>
        public string FDate { get; set; }

        /// <summary>
        ///  客户编码
        /// </summary>
        public string FCustCode { get; set; }


        /// <summary>
        /// 备注
        /// </summary>
        public string FMemo { get; set; }


        /// <summary>
        /// 明细
        /// </summary>
        public List<SaleDeliveryEntry> Entry { get; set; }
    }

    public class SaleDeliveryEntry
    {

        /// <summary>
        /// 存货编码
        /// </summary>
        public string FInvCode { get; set; }

        /// <summary>
        ///  数量
        /// </summary>
        public decimal FQuantity { get; set; }

        /// <summary>
        /// 金额 
        /// </summary>
        public string FAmount { get; set; }

        /// <summary>
        /// 备注 传单号
        /// </summary>
        public string FMemo { get; set; }

    }

    public class Structure
    {
        public string Label { get; set; }
        public string Column { get; set; }
    }

    /// <summary>
    /// 表单数据项
    /// </summary>
    public class FormItemModel
    {
        /// <summary>
        /// 表单键，request["key"]
        /// </summary>
        public string Key { set; get; }
        /// <summary>
        /// 表单值,上传文件时忽略，request["key"].value
        /// </summary>
        public string Value { set; get; }
        /// <summary>
        /// 是否是文件
        /// </summary>
        public bool IsFile
        {
            get
            {
                if (FileContent == null || FileContent.Length == 0)
                    return false;

                if (FileContent != null && FileContent.Length > 0 && string.IsNullOrWhiteSpace(FileName))
                    throw new Exception("上传文件时 FileName 属性值不能为空");
                return true;
            }
        }
        /// <summary>
        /// 上传的文件名
        /// </summary>
        public string FileName { set; get; }
        /// <summary>
        /// 上传的文件内容
        /// </summary>
        public Stream FileContent { set; get; }
    }


    public class TResult
    {
        public string Result { get; set; }
        public string Message { get; set; }
        public object Data { get; set; }
    }



    public DataTable ExcelToDataTable(string filepath, string sheetname, bool isFirstRowColumn)
    {
        ISheet sheet = null;//工作表
        DataTable data = new DataTable();

        var startrow = 0;
        IWorkbook workbook = null;
        using (FileStream fs = new FileStream(filepath, FileMode.Open, FileAccess.Read))
        {
            try
            {
                if (filepath.IndexOf(".xlsx") > 0) // 2007版本
                    workbook = new XSSFWorkbook(fs);
                else if (filepath.IndexOf(".xls") > 0) // 2003版本
                    workbook = new HSSFWorkbook(fs);
                if (sheetname != null)
                {
                    sheet = workbook.GetSheet(sheetname);
                    if (sheet == null) //如果没有找到指定的sheetName对应的sheet，则尝试获取第一个sheet
                    {
                        sheet = workbook.GetSheetAt(0);
                    }
                }
                else
                {
                    sheet = workbook.GetSheetAt(0);
                }
                if (sheet != null)
                {
                    IRow firstrow = sheet.GetRow(0);
                    int cellCount = firstrow.LastCellNum; //行最后一个cell的编号 即总的列数
                    if (isFirstRowColumn)
                    {
                        for (int i = firstrow.FirstCellNum; i < cellCount; i++)
                        {
                            ICell cell = firstrow.GetCell(i);
                            if (cell != null)
                            {
                                string cellvalue = cell.StringCellValue;
                                if (cellvalue != null)
                                {
                                    DataColumn column = new DataColumn(cellvalue);
                                    data.Columns.Add(column);
                                }
                            }
                        }
                        startrow = sheet.FirstRowNum + 1;
                    }
                    else
                    {
                        startrow = sheet.FirstRowNum;
                    }
                    //读数据行
                    int rowcount = sheet.LastRowNum;
                    for (int i = startrow; i <= rowcount; i++)
                    {
                        IRow row = sheet.GetRow(i);
                        if (row == null)
                        {
                            continue; //没有数据的行默认是null
                        }
                        DataRow datarow = data.NewRow();//具有相同架构的行
                        for (int j = row.FirstCellNum; j < cellCount; j++)
                        {
                            if (row.GetCell(j) != null)
                            {
                                datarow[j] = row.GetCell(j).ToString();
                            }
                        }
                        data.Rows.Add(datarow);
                    }
                }
                return data;
            }
            catch (System.Exception ex)
            {
                return null;
            }
            finally { fs.Close(); fs.Dispose(); }
        }
    }


    #region SafeParse
    public static bool SafeBool(object target, bool defaultValue)
    {
        if (target == null) return defaultValue;
        string tmp = target.ToString(); if (string.IsNullOrWhiteSpace(tmp)) return defaultValue;
        return SafeBool(tmp, defaultValue);
    }
    public static bool SafeBool(string text, bool defaultValue)
    {
        bool flag;
        if (bool.TryParse(text, out flag))
        {
            defaultValue = flag;
        }
        return defaultValue;
    }

    public static System.DateTime SafeDateTime(object target, System.DateTime defaultValue)
    {
        if (target == null) return defaultValue;
        string tmp = target.ToString(); if (string.IsNullOrWhiteSpace(tmp)) return defaultValue;
        return SafeDateTime(tmp, defaultValue);
    }
    public static System.DateTime SafeDateTime(string text, System.DateTime defaultValue)
    {
        System.DateTime time;
        if (System.DateTime.TryParse(text, out time))
        {
            defaultValue = time;
        }
        return defaultValue;
    }

    public static decimal SafeDecimal(object target, decimal defaultValue)
    {
        if (target == null) return defaultValue;
        string tmp = target.ToString(); if (string.IsNullOrWhiteSpace(tmp)) return defaultValue;
        return SafeDecimal(tmp, defaultValue);
    }
    public static decimal SafeDecimal(string text, decimal defaultValue)
    {
        decimal num;
        if (decimal.TryParse(text, out num))
        {
            defaultValue = num;
        }
        return defaultValue;
    }
    public static short SafeShort(object target, short defaultValue)
    {
        if (target == null) return defaultValue;
        string tmp = target.ToString(); if (string.IsNullOrWhiteSpace(tmp)) return defaultValue;
        return SafeShort(tmp, defaultValue);
    }
    public static short SafeShort(string text, short defaultValue)
    {
        short num;
        if (short.TryParse(text, out num))
        {
            defaultValue = num;
        }
        return defaultValue;
    }

    public static int SafeInt(object target, int defaultValue)
    {
        if (target == null) return defaultValue;
        string tmp = target.ToString(); if (string.IsNullOrWhiteSpace(tmp)) return defaultValue;
        return SafeInt(tmp, defaultValue);
    }
    public static int SafeInt(string text, int defaultValue)
    {
        int num;
        if (int.TryParse(text, out num))
        {
            defaultValue = num;
        }
        return defaultValue;
    }

    public static long SafeLong(object target, long defaultValue)
    {
        if (target == null) return defaultValue;
        string tmp = target.ToString(); if (string.IsNullOrWhiteSpace(tmp)) return defaultValue;
        if (string.IsNullOrWhiteSpace(tmp)) return defaultValue;
        return SafeLong(tmp, defaultValue);
    }
    public static long SafeLong(string text, long defaultValue)
    {
        long num;
        if (long.TryParse(text, out num))
        {
            defaultValue = num;
        }
        return defaultValue;
    }

    public static string SafeString(object target, string defaultValue)
    {
        if (null != target && "" != target.ToString())
        {
            return target.ToString();
        }
        return defaultValue;
    }

    #region SafeNullParse
    public static bool? SafeBool(object target, bool? defaultValue)
    {
        if (target == null) return defaultValue;
        string tmp = target.ToString();
        if (string.IsNullOrWhiteSpace(tmp)) return defaultValue;
        return SafeBool(tmp, defaultValue);
    }
    public static bool? SafeBool(string text, bool? defaultValue)
    {
        bool flag;
        if (bool.TryParse(text, out flag))
        {
            defaultValue = flag;
        }
        return defaultValue;
    }

    public static System.DateTime? SafeDateTime(object target, System.DateTime? defaultValue)
    {
        if (target == null) return defaultValue;
        string tmp = target.ToString();
        if (string.IsNullOrWhiteSpace(tmp)) return defaultValue;
        return SafeDateTime(tmp, defaultValue);
    }
    public static System.DateTime? SafeDateTime(string text, System.DateTime? defaultValue)
    {
        System.DateTime time;
        if (System.DateTime.TryParse(text, out time))
        {
            defaultValue = time;
        }
        return defaultValue;
    }

    public static decimal? SafeDecimal(object target, decimal? defaultValue)
    {
        if (target == null) return defaultValue;
        string tmp = target.ToString();
        if (string.IsNullOrWhiteSpace(tmp)) return defaultValue;
        return SafeDecimal(tmp, defaultValue);
    }
    public static decimal? SafeDecimal(string text, decimal? defaultValue)
    {
        decimal num;
        if (decimal.TryParse(text, out num))
        {
            defaultValue = num;
        }
        return defaultValue;
    }

    public static short? SafeShort(object target, short? defaultValue)
    {
        if (target == null) return defaultValue;
        string tmp = target.ToString();
        if (string.IsNullOrWhiteSpace(tmp)) return defaultValue;
        return SafeShort(tmp, defaultValue);
    }
    public static short? SafeShort(string text, short? defaultValue)
    {
        short num;
        if (short.TryParse(text, out num))
        {
            defaultValue = num;
        }
        return defaultValue;
    }

    public static int? SafeInt(object target, int? defaultValue)
    {
        if (target == null) return defaultValue;
        string tmp = target.ToString();
        if (string.IsNullOrWhiteSpace(tmp)) return defaultValue;
        return SafeInt(tmp, defaultValue);
    }
    public static int? SafeInt(string text, int? defaultValue)
    {
        int num;
        if (int.TryParse(text, out num))
        {
            defaultValue = num;
        }
        return defaultValue;
    }

    public static long? SafeLong(object target, long? defaultValue)
    {
        if (target == null) return defaultValue;
        string tmp = target.ToString();
        if (string.IsNullOrWhiteSpace(tmp)) return defaultValue;
        return SafeLong(tmp, defaultValue);
    }
    public static long? SafeLong(string text, long? defaultValue)
    {
        long num;
        if (long.TryParse(text, out num))
        {
            defaultValue = num;
        }
        return defaultValue;
    }
    #endregion

    #region SafeEnum
    /// <summary>
    /// 将枚举数值or枚举名称 安全转换为枚举对象
    /// </summary>
    /// <typeparam name="T">枚举类型</typeparam>
    /// <param name="value">数值or名称</param>
    /// <param name="defaultValue">默认值</param>
    /// <remarks>转换区分大小写</remarks>
    /// <returns></returns>
    public static T SafeEnum<T>(string value, T defaultValue) where T : struct
    {
        return SafeEnum<T>(value, defaultValue, false);
    }

    /// <summary>
    /// 将枚举数值or枚举名称 安全转换为枚举对象
    /// </summary>
    /// <typeparam name="T">枚举类型</typeparam>
    /// <param name="value">数值or名称</param>
    /// <param name="defaultValue">默认值</param>
    /// <param name="ignoreCase">是否忽略大小写 true 不区分大小写 | false 区分大小写</param>
    /// <returns></returns>
    public static T SafeEnum<T>(string value, T defaultValue, bool ignoreCase) where T : struct
    {
        T result;
        if (System.Enum.TryParse<T>(value, ignoreCase, out result))
        {
            if (System.Enum.IsDefined(typeof(T), result))
            {
                defaultValue = result;
            }
        }
        return defaultValue;
    }
    #endregion
    #endregion

    public static List<T> ToList<T>(DataTable dt)
    {
        var dataColumn = dt.Columns.Cast<DataColumn>().Select(c => c.ColumnName).ToList();

        var properties = typeof(T).GetProperties();
        string columnName = string.Empty;

        return dt.AsEnumerable().Select(row =>
        {
            var t = System.Activator.CreateInstance<T>();
            foreach (var p in properties)
            {
                columnName = p.Name;
                if (dataColumn.Contains(columnName))
                {
                    if (!p.CanWrite)
                        continue;

                    object value = row[columnName];
                    System.Type type = p.PropertyType;

                    if (value != System.DBNull.Value)
                    {
                        p.SetValue(t, System.Convert.ChangeType(value, type), null);
                    }
                }
            }
            return t;
        }).ToList();
    }

    public static void addLogErr(string SPName, string ErrDescribe)
    {
        string tracingFile = "C:/inetpub/wwwroot/log/";
        if (!Directory.Exists(tracingFile))
            Directory.CreateDirectory(tracingFile);
        string fileName = System.DateTime.Now.ToString("yyyyMMdd") + ".txt";
        tracingFile += fileName;
        if (tracingFile != System.String.Empty)
        {
            FileInfo file = new System.IO.FileInfo(tracingFile);
            StreamWriter debugWriter = new StreamWriter(file.Open(FileMode.Append, FileAccess.Write, FileShare.ReadWrite));
            debugWriter.WriteLine(SPName + " (" + System.DateTime.Now.ToString() + ") " + " :");
            debugWriter.WriteLine(ErrDescribe);
            debugWriter.WriteLine();
            debugWriter.Flush();
            debugWriter.Close();
        }
    }
    public List<Structure> struList = new List<Structure>() {

         new Structure() { Label = "单号",Column="FBillNo" },
         new Structure() { Label = "支付用户",Column="FPayUser" },
         new Structure() { Label = "酒类", Column="FInvName"},
         new Structure() { Label = "商铺名", Column="FCustomer"},
         new Structure() { Label = "设备号", Column="FDeviceNo"},
         new Structure() { Label = "代理", Column="FAgent"},
         new Structure() { Label = "所属代理", Column="FAgentCode"},
         new Structure() { Label = "省市区", Column="FAddress"},
         new Structure() { Label = "代理类型", Column="FAgentType"},
         new Structure() { Label = "规格两", Column="FSpecification"},
         new Structure() { Label = "优惠券", Column="FCoupon"},
         new Structure() { Label = "实付金额", Column="FAmount"},
         new Structure() { Label = "酒水销售", Column="FSellAmount"},
         new Structure() { Label = "店员奖励", Column="FStaffReward"},
         new Structure() { Label = "个人代理分成", Column="FPersonalAgent"},
         new Structure() { Label = "区县合伙人分成", Column="FPartner"},
         new Structure() { Label = "额外区县合伙人分成", Column="FAdditionalPartner"},
         new Structure() { Label = "订单状态", Column="FOrderStatus"},
         new Structure() { Label = "订单日期", Column="FOrderDate"},
         new Structure() { Label = "备注", Column="FMemo"},
         new Structure() { Label = "实际出酒ml", Column="FQuantity"}
    };

    public List<string> alllowExtend = new List<string>() { "application/vnd.ms-excel", "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet" };
    public void ProcessRequest(HttpContext context)
    {
        ZYSoft.DB.Common.Configuration.ConnectionString = LoadXML("ConnectionString");
        context.Response.ContentType = "text/plain";
        if (context.Request.Form["SelectApi"] != null)
        {
            string result = ""; string methodName = "";
            switch (context.Request.Form["SelectApi"].ToLower())
            {
                case "upload":
                    string errMsg = "";
                    List<Record> list = handleFile(context.Request, ref errMsg);
                    result = JsonConvert.SerializeObject(new
                    {
                        state = list.Count > 0 ? "success" : "error",
                        data = list,
                        msg = errMsg,
                        customers = list.Select(t => t.FCustomer).ToList().Distinct(),
                    });
                    break;
                case "check":
                    List<Record> dataSource = JsonConvert.DeserializeObject<List<Record>>(context.Request.Form["dataSource"] ?? "");
                    list = ReadFile(dataSource);
                    result = JsonConvert.SerializeObject(new
                    {
                        state = list.Count > 0 ? "success" : "error",
                        data = list,
                    });
                    break;
                case "save":
                    string formData = context.Request.Form["formData"] ?? "";
                    addLogErr("save", formData);
                    methodName = LoadXML("Method");
                    result = SaveBill(JsonConvert.DeserializeObject<SaleDelivery>(formData), methodName);
                    break;
                    break;
                default:
                    break;
            }
            context.Response.Write(result);
        }
    }

    public List<Record> handleFile(HttpRequest request, ref string filename)
    {
        List<Record> list = new List<Record>();
        try
        {
            HttpFileCollection files = request.Files;
            if (files.Count > 0)
            {
                HttpPostedFile file = files[0];
                string BasePath = HttpContext.Current.Request.PhysicalApplicationPath;
                addLogErr("ApplyForm", BasePath);
                BasePath = Path.Combine(BasePath, "tempexcel");
                addLogErr("ApplyForm", BasePath);
                if (!Directory.Exists(BasePath))
                {
                    Directory.CreateDirectory(BasePath);
                }
                string tempFileName = System.DateTime.Now.ToString("yyyyMMddHHmmss");
                string[] array = file.FileName.Split('.');

                string ExtendName = array.Length > 0 ? array[array.Length - 1] : "";

                if (alllowExtend.Contains(file.ContentType))
                {
                    BasePath = Path.Combine(BasePath, string.Format(@"{0}.{1}", tempFileName, ExtendName));

                    file.SaveAs(BasePath);
                    filename = string.Format(@"{0}.{1}", tempFileName, ExtendName);

                    DataTable dt = ExcelToDataTable(BasePath, null, true);
                    if (dt != null && dt.Rows.Count > 0)
                    {
                        dt = Transfer(dt);
                        list = GenericList(dt, ref filename);
                    }
                }
            }
            return list;
        }
        catch (System.Exception e)
        {
            return list;
        }
    }

    public List<Record> GenericList(DataTable dt, ref string errMsg)
    {
        errMsg = "";
        List<Record> list = new List<Record>();
        try
        {
            System.Type tt = typeof(Record);//获取指定名称的类型
            object ff = Activator.CreateInstance(tt, null);//创建指定类型实例
            PropertyInfo[] fields = ff.GetType().GetProperties();//获取指定对象的所有公共属性
            foreach (DataRow dr in dt.Rows)
            {
                Record obj = Activator.CreateInstance(tt, null) as Record;
                foreach (DataColumn dc in dt.Columns)
                {
                    foreach (PropertyInfo t in fields)
                    {
                        if (dc.ColumnName == t.Name)
                        {
                            if (dc.ColumnName.Equals("FIsValid"))
                            {
                                t.SetValue(obj, SafeBool(dr[dc.ColumnName], false), null);//给对象赋值
                            }
                            else if (dc.ColumnName.Equals("FErrorCount"))
                            {
                                t.SetValue(obj, SafeInt(dr[dc.ColumnName], 0), null);//给对象赋值
                            }
                            else
                            {
                                t.SetValue(obj, SafeString(dr[dc.ColumnName], ""), null);//给对象赋值
                            }
                            continue;
                        }
                    }

                }
                list.Add(obj);//将对象填充到list集合
            }
        }
        catch (Exception e)
        {
            errMsg = e.Message;
        }
        return list;
    }



    public DataTable Transfer(DataTable dt)
    {
        DataTable dtNew = new DataTable();
        dtNew = dt.Copy();
        foreach (DataColumn dc in dtNew.Columns)
        {
            Structure structure = struList.Find(f => f.Label.Equals(dc.ColumnName));
            if (structure != null)
            {
                dc.ColumnName = structure.Column;
            }
        }
        dtNew.Columns.Add("FIsValid", typeof(bool));
        dtNew.Columns.Add("FErrMsg", typeof(string));

        return dtNew;
    }

    public List<Record> ReadFile(List<Record> list)
    {
        try
        {
            list.ForEach(f =>
            {
                f.FErrorCount = 1;
                f.FErrorMsg = "尚未检查!";
                f.FIsValid = true;
            });

            #region 检查存货档案 
            string sql = string.Format(@"select code,name,specification from AA_Inventory");
            DataTable dtInv = ZYSoft.DB.BLL.Common.ExecuteDataTable(sql);
            List<Inv> listInv = ToList<Inv>(dtInv);
            list.ForEach(f =>
            {
                Inv item = listInv.Find(inv => inv.name.ToLower().Equals(f.FInvName.ToLower()) &&
                 inv.specification.ToLower().Equals(f.FSpecification.ToLower()));
                if (item == null)
                {
                    f.FErrorCount += 1;
                    f.FErrorMsg += "没有这个存货档案!\r\n";
                }
                else
                {
                    f.FInvCode = item.code;
                }
            });
            #endregion

            #region 检查客户
            sql = string.Format(@"select code,name FROM AA_Partner");
            DataTable dtProject = ZYSoft.DB.BLL.Common.ExecuteDataTable(sql);
            List<Customer> listProject = ToList<Customer>(dtProject);
            list.ForEach(f =>
            {
                Customer item = listProject.Find(customer => customer.name.Equals(f.FCustomer));
                if (item == null)
                {
                    f.FErrorCount += 1;
                    f.FErrorMsg += "没有这个客户编码!\r\n";
                }
                else
                {
                    f.FCustCode = item.code;
                }
            });
            #endregion

            #region 检查单号是否导入过
            sql = string.Format(@"select isnull(detailmemo,'')detailmemo from SA_SaleDelivery_b");
            DataTable dtMemo = ZYSoft.DB.BLL.Common.ExecuteDataTable(sql);
            List<BillRecord> listMemo = ToList<BillRecord>(dtMemo);
            list.ForEach(f =>
            {
                BillRecord item = listMemo.Find(memo => memo.detailmemo == f.FBillNo);
                if (item != null)
                {
                    f.FErrorCount += 1;
                    f.FErrorMsg += "当前订单已存在!\r\n";
                }
            });
            #endregion

            list.ForEach(f =>
            {
                f.FIsValid = f.FErrorCount <= 1;
                f.FErrorMsg = f.FErrorCount <= 1 ? "检查通过!" : f.FErrorMsg;
            });
            return list;
        }
        catch (System.Exception)
        {
            return list;
        }
    }



    public string LoadXML(string key)
    {
        string filename = HttpContext.Current.Request.PhysicalApplicationPath + @"zysoftweb.config";
        XmlDocument xmldoc = new XmlDocument();
        xmldoc.Load(filename);
        XmlNode node = xmldoc.SelectSingleNode("/configuration/appSettings");

        string return_value = string.Empty;
        foreach (XmlElement el in node)//读元素值 
        {
            if (el.Attributes["key"].Value.ToLower().Equals(key.ToLower()))
            {
                return_value = el.Attributes["value"].Value;
                break;
            }
        }

        return return_value;
    }

    public string doPost(string url, List<FormItemModel> formItems, CookieContainer cookieContainer = null, string refererUrl = null,
   System.Text.Encoding encoding = null, int timeOut = 20000)
    {
        HttpWebRequest request = (HttpWebRequest)WebRequest.Create(url);
        #region 初始化请求对象
        request.Method = "POST";
        request.Timeout = timeOut;
        request.Accept = "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8";
        request.KeepAlive = true;
        request.UserAgent = "Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/31.0.1650.57 Safari/537.36";
        if (!string.IsNullOrEmpty(refererUrl))
            request.Referer = refererUrl;
        if (cookieContainer != null)
            request.CookieContainer = cookieContainer;
        #endregion

        string boundary = "----" + DateTime.Now.Ticks.ToString("x");//分隔符
        request.ContentType = string.Format("multipart/form-data; boundary={0}", boundary);
        //请求流
        var postStream = new MemoryStream();
        #region 处理Form表单请求内容
        //是否用Form上传文件
        var formUploadFile = formItems != null && formItems.Count > 0;
        if (formUploadFile)
        {
            //文件数据模板
            string fileFormdataTemplate =
                "\r\n--" + boundary +
                "\r\nContent-Disposition: form-data; name=\"{0}\"; filename=\"{1}\"" +
                "\r\nContent-Type: application/octet-stream" +
                "\r\n\r\n";
            //文本数据模板
            string dataFormdataTemplate =
                "\r\n--" + boundary +
                "\r\nContent-Disposition: form-data; name=\"{0}\"" +
                "\r\n\r\n{1}";
            foreach (var item in formItems)
            {
                string formdata = null;
                if (item.IsFile)
                {
                    //上传文件
                    formdata = string.Format(
                        fileFormdataTemplate,
                        item.Key, //表单键
                        item.FileName);
                }
                else
                {
                    //上传文本
                    formdata = string.Format(
                        dataFormdataTemplate,
                        item.Key,
                        item.Value);
                }

                //统一处理
                byte[] formdataBytes = null;
                //第一行不需要换行
                if (postStream.Length == 0)
                    formdataBytes = System.Text.Encoding.UTF8.GetBytes(formdata.Substring(2, formdata.Length - 2));
                else
                    formdataBytes = System.Text.Encoding.UTF8.GetBytes(formdata);
                postStream.Write(formdataBytes, 0, formdataBytes.Length);

                //写入文件内容
                if (item.FileContent != null && item.FileContent.Length > 0)
                {
                    using (var stream = item.FileContent)
                    {
                        byte[] buffer = new byte[1024];
                        int bytesRead = 0;
                        while ((bytesRead = stream.Read(buffer, 0, buffer.Length)) != 0)
                        {
                            postStream.Write(buffer, 0, bytesRead);
                        }
                    }
                }
            }
            //结尾
            var footer = System.Text.Encoding.UTF8.GetBytes("\r\n--" + boundary + "--\r\n");
            postStream.Write(footer, 0, footer.Length);
        }
        else
        {
            request.ContentType = "application/x-www-form-urlencoded";
        }
        #endregion

        request.ContentLength = postStream.Length;

        #region 输入二进制流
        if (postStream != null)
        {
            postStream.Position = 0;
            //直接写入流
            Stream requestStream = request.GetRequestStream();

            byte[] buffer = new byte[1024];
            int bytesRead = 0;
            while ((bytesRead = postStream.Read(buffer, 0, buffer.Length)) != 0)
            {
                requestStream.Write(buffer, 0, bytesRead);
            }
            postStream.Close();//关闭文件访问
        }
        #endregion

        HttpWebResponse response = (HttpWebResponse)request.GetResponse();
        if (cookieContainer != null)
        {
            response.Cookies = cookieContainer.GetCookies(response.ResponseUri);
        }

        using (Stream responseStream = response.GetResponseStream())
        {
            using (StreamReader myStreamReader = new StreamReader(responseStream, encoding ?? System.Text.Encoding.UTF8))
            {
                string retString = myStreamReader.ReadToEnd();
                return retString;
            }
        }
    }

    public string SaveBill<T>(T formData, string methosName)
    {
        try
        {
            string errMsg = "";
            if (BeforeSave(formData, ref errMsg))
            {
                var WsUrl = LoadXML("WsUrl");
                var formDatas = new List<FormItemModel>();
                //添加文本
                formDatas.Add(new FormItemModel()
                {
                    Key = "MethodName",
                    Value = methosName
                });          //添加文本
                formDatas.Add(new FormItemModel()
                {
                    Key = "JSON",
                    Value = JsonConvert.SerializeObject(formData)
                });

                addLogErr("SaveBill", JsonConvert.SerializeObject(formDatas));

                //提交表单
                var json = doPost(WsUrl, formDatas);
                TResult result = JsonConvert.DeserializeObject<TResult>(json);
                return JsonConvert.SerializeObject(new
                {
                    status = result.Result == "Y" ? "success" : "error",
                    data = "",
                    msg = result.Result == "Y" ? "生成单据成功!" : result.Message
                });
            }
            else
            {
                return JsonConvert.SerializeObject(new
                {
                    status = "error",
                    data = "",
                    msg = "保存单据失败!"
                });
            }
        }
        catch (Exception)
        {
            return JsonConvert.SerializeObject(new
            {
                status = "error",
                data = "",
                msg = "生成单据发生异常!"
            });
        }
    }

    public bool BeforeSave<T>(T formData, ref string msg)
    {
        return true;
    }

    public bool IsReusable
    {
        get
        {
            return false;
        }
    }

}