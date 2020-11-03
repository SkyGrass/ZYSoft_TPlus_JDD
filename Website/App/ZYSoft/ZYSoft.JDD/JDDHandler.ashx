<%@ WebHandler Language="C#" Class="JDDHandler" %>

using System;
using System.Web;
using System.Data;
using Newtonsoft.Json;
using System.Collections.Generic;
using System.Xml;
using System.Net;
using System.IO;
public class JDDHandler : IHttpHandler
{
    public class Result
    {
        public string status { get; set; }
        public object data { get; set; }
        public string msg { get; set; }
    }

    public class PostForm
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
        /// 订单ID
        /// </summary>
        public string FSOBillID { get; set; }
        /// <summary>
        /// 订单 明细ID
        /// </summary>
        public string FSOBillEntryID { get; set; }
        /// <summary>
        ///  产品编码
        /// </summary>
        public string FInvCode { get; set; }
        /// <summary>
        ///  版本号
        /// </summary>
        public string FVersion { get; set; }
        /// <summary>
        /// 明细
        /// </summary>
        public List<BomEntry> Entry { get; set; }
    }

    public class BomEntry
    {
        /// <summary>
        /// 存货编码
        /// </summary>
        public string FInvCode { get; set; }

        /// <summary>
        ///  需求数量
        /// </summary>
        public decimal FQuantity { get; set; }
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


    public void ProcessRequest(HttpContext context)
    {
        ZYSoft.DB.Common.Configuration.ConnectionString = LoadXML("ConnectionString");
        context.Response.ContentType = "text/plain";
        if (context.Request.Form["SelectApi"] != null)
        {
            string result = ""; string methodName = "";
            switch (context.Request.Form["SelectApi"].ToLower())
            {
                case "getconnect":
                    result = ZYSoft.DB.Common.Configuration.ConnectionString;
                    break;
                case "getallmaterialinfo":
                    result = GetMaterialInfo();
                    break;
                case "getorder":
                    string ordercode = context.Request.Form["ordercode"] ?? "";
                    string customer = context.Request.Form["customer"] ?? "";
                    string begindate = context.Request.Form["begindate"] ?? DateTime.Now.ToString("yyyy-MM-dd");
                    string enddate = context.Request.Form["endate"] ?? DateTime.Now.ToString("yyyy-MM-dd");
                    result = GetOrder(ordercode, customer, begindate, enddate);
                    break;
                case "getorderdetail":
                    string idbom = context.Request.Form["idbom"] ?? "";
                    result = GetOrderDetail(idbom);
                    break;
                case "save":
                    string formData = context.Request.Form["formData"] ?? "";
                    addLogErr("save", formData);
                    methodName = LoadXML("Method");
                    result = SaveBill(JsonConvert.DeserializeObject<PostForm>(formData), methodName);
                    break;
                default: break;
            }
            context.Response.Write(result);
        }
    }

    /*查询进货单数据*/
    public string GetMaterialInfo()
    {
        var list = new List<Result>();
        try
        {
            string sql = string.Format(@"SELECT t1.id,t1.code,t1.name,specification,idunit,T2.name unitname
                        FROM dbo.AA_Inventory  T1 JOIN dbo.AA_Unit T2 ON T1.idunit=T2.ID where t1.disabled=0");
            DataTable dt = ZYSoft.DB.BLL.Common.ExecuteDataTable(sql);
            return JsonConvert.SerializeObject(new
            {
                status = dt.Rows.Count > 0 ? "success" : "error",
                data = dt,
                msg = ""
            });
        }
        catch (Exception ex)
        {
            return JsonConvert.SerializeObject(new
            {
                status = "error",
                data = new List<string>(),
                msg = ex.Message
            });
        }
    }


    /// <summary>
    /// 销售订单
    /// </summary>
    /// <returns></returns>
    public string GetOrder(string ordercode, string customer, string begindate, string endate)
    {
        var list = new List<Result>();
        try
        {
            string sqlWhere = string.Empty;
            if (!string.IsNullOrEmpty(ordercode))
            {
                sqlWhere += string.Format(@" and t1.code like '%{0}%'", ordercode);
            }
            if (!string.IsNullOrEmpty(customer))
            {
                sqlWhere += string.Format(@" and (t3.name like '%{0}%' or t3.code like '%{0}%')", customer);
            }
            if (!string.IsNullOrEmpty(begindate))
            {
                sqlWhere += string.Format(@" and t1.voucherdate >= '{0}'", begindate);
            }
            if (!string.IsNullOrEmpty(endate))
            {
                sqlWhere += string.Format(@" and t1.voucherdate <= '{0} 23:59:59'", endate);
            }

            string sql = string.Format(@"select T1.id,t2.id as identry,T1.code,T1.voucherdate,T3.name customer,
                                        T2.idinventory,T4.code cinvcode,t4.name cinvname,
                                        t4.specification cinvstd,T41.name cunit,t2.quantity,t2.idbom,
                                         T5.version  
                                        from SA_SaleOrder T1 LEFT JOIN SA_SaleOrder_b T2 ON T1.ID=T2.idSaleOrderDTO
                                        LEFT JOIN AA_Partner T3 ON T1.idcustomer= T3.ID
                                        LEFT JOIN AA_Inventory T4 ON T2.idinventory=T4.ID
                                        LEFT JOIN AA_Unit T41 ON T4.idunit =T41.ID
                                        LEFT OUTER JOIN AA_BOM T5 ON T2.idbom = T5.ID where 1=1 {0}", sqlWhere);
            DataTable dt = ZYSoft.DB.BLL.Common.ExecuteDataTable(sql);
            return JsonConvert.SerializeObject(new
            {
                status = dt != null && dt.Rows.Count > 0 ? "success" : "error",
                data = dt,
                msg = ""
            });
        }
        catch (Exception ex)
        {
            return JsonConvert.SerializeObject(new
            {
                status = "error",
                data = new List<string>(),
                msg = ex.Message
            });
        }
    }

    public string GetOrderDetail(string idbom = "-1")
    {
        var list = new List<Result>();
        try
        {
            string sql = string.Format(@" SELECT T1.id,T1.code,T1.name,T1.version,
                                    T2.idinventory,T3.code cinvcode,t3.name cinvname,
                                    t3.specification cinvstd,T4.name cunit,requiredquantity 
                                    FROM AA_BOM T1 LEFT JOIN AA_BOMChild T2 ON T1.ID=T2.idbom
                                    LEFT JOIN AA_Inventory T3 ON T2.idinventory=T3.ID
                                    LEFT JOIN AA_Unit T4 ON T3.idunit =T4.ID WHERE T1.ID={0}", idbom);
            DataTable dt = ZYSoft.DB.BLL.Common.ExecuteDataTable(sql);
            return JsonConvert.SerializeObject(new
            {
                status = dt != null && dt.Rows.Count > 0 ? "success" : "error",
                data = dt,
                msg = ""
            });
        }
        catch (Exception ex)
        {
            return JsonConvert.SerializeObject(new
            {
                status = "error",
                data = new List<string>(),
                msg = ex.Message
            });
        }
    }

    public bool BeforeSave<T>(T formData, ref string msg)
    {
        return true;
    }


    /*保存单据*/
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

    public static void addLogErr(string SPName, string ErrDescribe)
    {
        string tracingFile = "C:/inetpub/wwwroot/log/";
        if (!Directory.Exists(tracingFile))
            Directory.CreateDirectory(tracingFile);
        string fileName = DateTime.Now.ToString("yyyyMMdd") + ".txt";
        tracingFile += fileName;
        if (tracingFile != string.Empty)
        {
            FileInfo file = new FileInfo(tracingFile);
            StreamWriter debugWriter = new StreamWriter(file.Open(FileMode.Append, FileAccess.Write, FileShare.ReadWrite));
            debugWriter.WriteLine(SPName + " (" + DateTime.Now.ToString() + ") " + " :");
            debugWriter.WriteLine(ErrDescribe);
            debugWriter.WriteLine();
            debugWriter.Flush();
            debugWriter.Close();
        }
    }

    public string LoadXML(string key)
    {
        string return_value = string.Empty;
        try
        {
            string filename = HttpContext.Current.Request.PhysicalApplicationPath + @"zysoftweb.config";
            addLogErr("LoadXML", filename);
            XmlDocument xmldoc = new XmlDocument();
            xmldoc.Load(filename);
            XmlNode node = xmldoc.SelectSingleNode("/configuration/appSettings");


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
        catch (Exception e)
        {
            addLogErr("LoadXML", e.Message);
            return return_value;
        }
    }

    public bool IsReusable
    {
        get
        {
            return false;
        }
    }

}