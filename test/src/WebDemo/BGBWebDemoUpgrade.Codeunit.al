namespace FlemmingBakkensen.BCGrokBot.Test.WebDemo;

codeunit 50155 "BGB Web Demo Upgrade"
{
    Subtype = Upgrade;
    Access = Internal;

    trigger OnUpgradePerCompany()
    var
        WebDemoRegistration: Codeunit "BGB Web Demo Registration";
    begin
        WebDemoRegistration.Register();
    end;
}
