namespace FlemmingBakkensen.BCGrokBot.Test.WebDemo;

using System.Integration;

codeunit 50156 "BGB Web Demo Registration"
{
    Access = Internal;

    var
        ServiceNameTok: Label 'BGBWebDemo', Locked = true;

    /// <summary>
    /// Publishes codeunit "BGB Web Demo Setup" as OData web service BGBWebDemo (idempotent).
    /// </summary>
    procedure Register()
    var
        TenantWebService: Record "Tenant Web Service";
        WebServiceManagement: Codeunit "Web Service Management";
    begin
        WebServiceManagement.CreateTenantWebService(TenantWebService."Object Type"::Codeunit, Codeunit::"BGB Web Demo Setup", ServiceNameTok, true);
    end;
}
