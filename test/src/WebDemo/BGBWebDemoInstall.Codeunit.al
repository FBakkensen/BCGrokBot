namespace FlemmingBakkensen.BCGrokBot.Test.WebDemo;

using System.Integration;

codeunit 50154 "BGB Web Demo Install"
{
    Subtype = Install;
    Access = Internal;

    trigger OnInstallAppPerCompany()
    var
        WebDemoRegistration: Codeunit "BGB Web Demo Registration";
    begin
        WebDemoRegistration.Register();
    end;
}
