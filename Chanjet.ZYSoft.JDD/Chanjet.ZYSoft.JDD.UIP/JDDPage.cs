using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Ufida.T.EAP.AppBase;
using Ufida.T.BAP.Web.Base;
using System.Web.UI.WebControls;
using Chanjet.ZYSoft.JDD.Interface;
using Ufida.T.EAP.Aop;
using Ufida.T.EAP.DataStruct.Context;
using System.Web;
using Ufida.T.EAP.Dal;

namespace Chanjet.ZYSoft.JDD.UIP
{
    public class JDDPage : IAppHandler
    {
        GenericController controller;
        IJDD interfaceService;
        Label lblUserName;
        Label lbUserId;
        Label lbUserCode;
        public void AppEventHandler(object sender, AppEventArgs e)
        {
            controller = sender as GenericController;

            lblUserName = controller.GetViewControl("lblUserName") as Label;

            lbUserId = controller.GetViewControl("lbUserId") as Label;

            lbUserCode = controller.GetViewControl("lbUserCode") as Label;

            interfaceService = ServiceFactory.getService<IJDD>();

            Page_Load(sender, e);
        }

        protected void Page_Load(object sender, EventArgs e)
        {
            UserInfo userInfo = HttpContext.Current.Session["UserInfo"] as UserInfo;
            lblUserName.Text = userInfo.PersonName;
            lbUserId.Text = userInfo.UserID;
            lbUserCode.Text = userInfo.UserName;
        }
    }
}
