#include <a_samp>

#define DIALOG_REGISTER   1
#define DIALOG_LOGIN      2
#define FOLDER_COMPTES    "Comptes/%s.ini"

#define COLOR_INFO        0x33CCFFFF
#define COLOR_SUCCESS     0x33FF33FF
#define COLOR_ERROR       0xFF3333FF
#define COLOR_ADMIN       0xFFAA00FF

enum E_PLAYER_DATA
{
    pArgent,
    pAdmin,
    bool:pConnecte
};

new PlayerInfo[MAX_PLAYERS][E_PLAYER_DATA];
new g_TempsInitial;

forward SauvegarderCompte(playerid);
forward ChargerCompte(playerid, const password[]);

main()
{
    print("\n--------------------------------------------------");
    print("   Life City RP - Gamemode charge avec succes !");
    print("--------------------------------------------------\n");
}

public OnGameModeInit()
{
    SetGameModeText("Life City RP");
    ShowPlayerMarkers(1);
    UsePlayerPedAnims();
    DisableInteriorEnterExits();
    SetWorldTime(12);
    SetWeather(1);
    g_TempsInitial = gettime();

    // Quelques vehicules civils de depart a Pershing Square (LS)
    AddStaticVehicleEx(411, 1488.0, -1732.0, 13.4, 90.0, 1, 1, 600); // Infernus
    AddStaticVehicleEx(560, 1488.0, -1727.0, 13.4, 90.0, 3, 3, 600); // Sultan
    AddStaticVehicleEx(462, 1488.0, -1722.0, 13.4, 90.0, 6, 6, 600); // Faggio
    AddStaticVehicleEx(462, 1488.0, -1717.0, 13.4, 90.0, 6, 6, 600); // Faggio
    return 1;
}

public OnGameModeExit()
{
    for (new i = 0; i < MAX_PLAYERS; i++)
    {
        if (IsPlayerConnected(i) && PlayerInfo[i][pConnecte])
        {
            SauvegarderCompte(i);
        }
    }
    return 1;
}

public OnPlayerConnect(playerid)
{
    PlayerInfo[playerid][pArgent] = 2500;
    PlayerInfo[playerid][pAdmin] = 0;
    PlayerInfo[playerid][pConnecte] = false;

    SendClientMessage(playerid, COLOR_INFO, "Bienvenue sur Life City RP !");

    new nom[MAX_PLAYER_NAME], chemin[128];
    GetPlayerName(playerid, nom, sizeof(nom));
    format(chemin, sizeof(chemin), FOLDER_COMPTES, nom);

    if (fexist(chemin))
    {
        ShowPlayerDialog(
            playerid,
            DIALOG_LOGIN,
            DIALOG_STYLE_PASSWORD,
            "Life City RP - Connexion",
            "Ce compte existe deja.\nEntrez votre mot de passe pour vous connecter :",
            "Connexion",
            "Quitter"
        );
    }
    else
    {
        ShowPlayerDialog(
            playerid,
            DIALOG_REGISTER,
            DIALOG_STYLE_PASSWORD,
            "Life City RP - Inscription",
            "Bienvenue sur Life City RP !\nChoisissez un mot de passe (4 caracteres minimum) :",
            "Creer",
            "Quitter"
        );
    }
    return 1;
}

public OnPlayerDisconnect(playerid, reason)
{
    #pragma unused reason
    if (PlayerInfo[playerid][pConnecte])
    {
        SauvegarderCompte(playerid);
    }
    PlayerInfo[playerid][pConnecte] = false;
    return 1;
}

public OnPlayerSpawn(playerid)
{
    SetPlayerPos(playerid, 1481.0, -1740.0, 13.5);
    SetPlayerFacingAngle(playerid, 0.0);
    SetCameraBehindPlayer(playerid);
    ResetPlayerMoney(playerid);
    GivePlayerMoney(playerid, PlayerInfo[playerid][pArgent]);
    return 1;
}

public OnDialogResponse(playerid, dialogid, response, listitem, inputtext[])
{
    #pragma unused listitem
    new nom[MAX_PLAYER_NAME], chemin[128], msg[144];
    GetPlayerName(playerid, nom, sizeof(nom));
    format(chemin, sizeof(chemin), FOLDER_COMPTES, nom);

    if (dialogid == DIALOG_REGISTER)
    {
        if (!response)
        {
            SendClientMessage(playerid, COLOR_ERROR, "Vous avez quitte l'inscription.");
            Kick(playerid);
            return 1;
        }
        if (strlen(inputtext) < 4 || strlen(inputtext) > 32)
        {
            SendClientMessage(playerid, COLOR_ERROR, "Le mot de passe doit contenir entre 4 et 32 caracteres.");
            ShowPlayerDialog(
                playerid,
                DIALOG_REGISTER,
                DIALOG_STYLE_PASSWORD,
                "Life City RP - Inscription",
                "Mot de passe invalide (4 a 32 caracteres).\nEntrez un mot de passe :",
                "Creer",
                "Quitter"
            );
            return 1;
        }

        new File:fichier = fopen(chemin, io_write);
        if (fichier)
        {
            new ligne[128];
            format(ligne, sizeof(ligne), "Password=%s\r\nMoney=2500\r\nAdmin=0\r\n", inputtext);
            fwrite(fichier, ligne);
            fclose(fichier);
        }

        PlayerInfo[playerid][pArgent] = 2500;
        PlayerInfo[playerid][pAdmin] = 0;
        PlayerInfo[playerid][pConnecte] = true;

        format(msg, sizeof(msg), "Compte cree pour %s ! Depart avec $%d.", nom, PlayerInfo[playerid][pArgent]);
        SendClientMessage(playerid, COLOR_SUCCESS, msg);
        SpawnPlayer(playerid);
        return 1;
    }

    if (dialogid == DIALOG_LOGIN)
    {
        if (!response)
        {
            SendClientMessage(playerid, COLOR_ERROR, "Connexion annulee.");
            Kick(playerid);
            return 1;
        }
        if (!ChargerCompte(playerid, inputtext))
        {
            SendClientMessage(playerid, COLOR_ERROR, "Mot de passe incorrect !");
            ShowPlayerDialog(
                playerid,
                DIALOG_LOGIN,
                DIALOG_STYLE_PASSWORD,
                "Life City RP - Connexion",
                "Mot de passe incorrect. Reessayez :",
                "Connexion",
                "Quitter"
            );
            return 1;
        }

        PlayerInfo[playerid][pConnecte] = true;
        format(msg, sizeof(msg), "Bon retour sur Life City RP, %s !", nom);
        SendClientMessage(playerid, COLOR_SUCCESS, msg);
        SpawnPlayer(playerid);
        return 1;
    }
    return 0;
}

public OnPlayerCommandText(playerid, cmdtext[])
{
    if (!strcmp(cmdtext, "/aide", true))
    {
        SendClientMessage(playerid, COLOR_INFO, "=== Commandes Life City RP ===");
        SendClientMessage(playerid, COLOR_INFO, "/aide - /stats - /donnerargent [id] [montant]");
        if (PlayerInfo[playerid][pAdmin] >= 1)
        {
            SendClientMessage(playerid, COLOR_ADMIN, "Admin : /veh [id_modele] - /reparer - /meteo [id] - /heure [0-23]");
        }
        return 1;
    }

    if (!strcmp(cmdtext, "/stats", true))
    {
        new nom[MAX_PLAYER_NAME], ligne[128], uptime = gettime() - g_TempsInitial;
        GetPlayerName(playerid, nom, sizeof(nom));
        PlayerInfo[playerid][pArgent] = GetPlayerMoney(playerid);

        format(ligne, sizeof(ligne), "Joueur : %s | Argent : $%d | Niveau Admin : %d", nom, PlayerInfo[playerid][pArgent], PlayerInfo[playerid][pAdmin]);
        SendClientMessage(playerid, COLOR_INFO, ligne);
        format(ligne, sizeof(ligne), "Temps serveur actif : %d min %d sec", uptime / 60, uptime % 60);
        SendClientMessage(playerid, COLOR_INFO, ligne);
        return 1;
    }

    if (!strncmp(cmdtext, "/donnerargent ", 14, true))
    {
        new targetid, montant;
        if (sscanf_simple(cmdtext[14], targetid, montant))
        {
            SendClientMessage(playerid, COLOR_ERROR, "Usage : /donnerargent [ID] [Montant]");
            return 1;
        }
        if (!IsPlayerConnected(targetid) || targetid == playerid)
        {
            SendClientMessage(playerid, COLOR_ERROR, "Joueur invalide ou deconnecte.");
            return 1;
        }
        if (montant <= 0 || GetPlayerMoney(playerid) < montant)
        {
            SendClientMessage(playerid, COLOR_ERROR, "Montant invalide ou fonds insuffisants.");
            return 1;
        }

        new Float:x, Float:y, Float:z;
        GetPlayerPos(playerid, x, y, z);
        if (!IsPlayerInRangeOfPoint(targetid, 8.0, x, y, z))
        {
            SendClientMessage(playerid, COLOR_ERROR, "Vous devez etre proche du joueur (8m max).");
            return 1;
        }

        GivePlayerMoney(playerid, -montant);
        GivePlayerMoney(targetid, montant);
        PlayerInfo[playerid][pArgent] = GetPlayerMoney(playerid);
        PlayerInfo[targetid][pArgent] = GetPlayerMoney(targetid);

        new nomDonneur[MAX_PLAYER_NAME], nomReceveur[MAX_PLAYER_NAME], msg[144];
        GetPlayerName(playerid, nomDonneur, sizeof(nomDonneur));
        GetPlayerName(targetid, nomReceveur, sizeof(nomReceveur));

        format(msg, sizeof(msg), "Vous avez donne $%d a %s.", montant, nomReceveur);
        SendClientMessage(playerid, COLOR_SUCCESS, msg);
        format(msg, sizeof(msg), "%s vous a donne $%d.", nomDonneur, montant);
        SendClientMessage(targetid, COLOR_SUCCESS, msg);
        return 1;
    }

    if (!strncmp(cmdtext, "/veh ", 5, true))
    {
        if (PlayerInfo[playerid][pAdmin] < 1)
        {
            SendClientMessage(playerid, COLOR_ERROR, "Acces refuse (Admin requis).");
            return 1;
        }
        new modelid = strval(cmdtext[5]);
        if (modelid < 400 || modelid > 611)
        {
            SendClientMessage(playerid, COLOR_ERROR, "Usage : /veh [ID modele entre 400 et 611]");
            return 1;
        }
        new Float:x, Float:y, Float:z, Float:a;
        GetPlayerPos(playerid, x, y, z);
        GetPlayerFacingAngle(playerid, a);
        new vid = CreateVehicle(modelid, x + 2.0, y, z + 0.5, a, -1, -1, 600);
        PutPlayerInVehicle(playerid, vid, 0);
        SendClientMessage(playerid, COLOR_ADMIN, "Vehicule spawn avec succes.");
        return 1;
    }

    if (!strcmp(cmdtext, "/reparer", true))
    {
        if (PlayerInfo[playerid][pAdmin] < 1)
        {
            SendClientMessage(playerid, COLOR_ERROR, "Acces refuse (Admin requis).");
            return 1;
        }
        new vehid = GetPlayerVehicleID(playerid);
        if (vehid == 0)
        {
            SendClientMessage(playerid, COLOR_ERROR, "Vous devez etre dans un vehicule.");
            return 1;
        }
        RepairVehicle(vehid);
        SendClientMessage(playerid, COLOR_ADMIN, "Vehicule repare.");
        return 1;
    }

    if (!strncmp(cmdtext, "/meteo ", 7, true))
    {
        if (PlayerInfo[playerid][pAdmin] < 1)
        {
            SendClientMessage(playerid, COLOR_ERROR, "Acces refuse (Admin requis).");
            return 1;
        }
        new weatherid = strval(cmdtext[7]);
        SetWeather(weatherid);
        SendClientMessage(playerid, COLOR_ADMIN, "Meteo mise a jour.");
        return 1;
    }

    if (!strncmp(cmdtext, "/heure ", 7, true))
    {
        if (PlayerInfo[playerid][pAdmin] < 1)
        {
            SendClientMessage(playerid, COLOR_ERROR, "Acces refuse (Admin requis).");
            return 1;
        }
        new hour = strval(cmdtext[7]);
        if (hour < 0 || hour > 23)
        {
            SendClientMessage(playerid, COLOR_ERROR, "Usage : /heure [0 a 23]");
            return 1;
        }
        SetWorldTime(hour);
        SendClientMessage(playerid, COLOR_ADMIN, "Heure du serveur mise a jour.");
        return 1;
    }
    return 0;
}

stock sscanf_simple(const str[], &arg1, &arg2)
{
    new pos = 0;
    while (str[pos] == ' ') pos++;
    if (str[pos] == '\0') return 1;
    arg1 = strval(str[pos]);

    while (str[pos] != '\0' && str[pos] != ' ') pos++;
    while (str[pos] == ' ') pos++;
    if (str[pos] == '\0') return 1;
    arg2 = strval(str[pos]);
    return 0;
}

public SauvegarderCompte(playerid)
{
    new nom[MAX_PLAYER_NAME], chemin[128], mdp[64] = "";
    GetPlayerName(playerid, nom, sizeof(nom));
    format(chemin, sizeof(chemin), FOLDER_COMPTES, nom);

    new File:lecture = fopen(chemin, io_read);
    if (lecture)
    {
        new ligne[128];
        while (fread(lecture, ligne))
        {
            if (!strncmp(ligne, "Password=", 9))
            {
                strmid(mdp, ligne, 9, strlen(ligne), sizeof(mdp));
                strip_newline(mdp);
                break;
            }
        }
        fclose(lecture);
    }

    PlayerInfo[playerid][pArgent] = GetPlayerMoney(playerid);
    new File:ecriture = fopen(chemin, io_write);
    if (ecriture)
    {
        new sortie[128];
        format(sortie, sizeof(sortie), "Password=%s\r\nMoney=%d\r\nAdmin=%d\r\n", mdp, PlayerInfo[playerid][pArgent], PlayerInfo[playerid][pAdmin]);
        fwrite(ecriture, sortie);
        fclose(ecriture);
    }
    return 1;
}

public ChargerCompte(playerid, const password[])
{
    new nom[MAX_PLAYER_NAME], chemin[128];
    GetPlayerName(playerid, nom, sizeof(nom));
    format(chemin, sizeof(chemin), FOLDER_COMPTES, nom);

    new File:fichier = fopen(chemin, io_read);
    if (!fichier) return 0;

    new ligne[128], mdpFichier[64] = "", argentFichier = 2500, adminFichier = 0;
    while (fread(fichier, ligne))
    {
        if (!strncmp(ligne, "Password=", 9))
        {
            strmid(mdpFichier, ligne, 9, strlen(ligne), sizeof(mdpFichier));
            strip_newline(mdpFichier);
        }
        else if (!strncmp(ligne, "Money=", 6))
        {
            argentFichier = strval(ligne[6]);
        }
        else if (!strncmp(ligne, "Admin=", 6))
        {
            adminFichier = strval(ligne[6]);
        }
    }
    fclose(fichier);

    if (strcmp(mdpFichier, password, false) != 0)
    {
        return 0;
    }

    PlayerInfo[playerid][pArgent] = argentFichier;
    PlayerInfo[playerid][pAdmin] = adminFichier;
    return 1;
}

stock strip_newline(str[])
{
    new len = strlen(str);
    while (len > 0 && (str[len - 1] == '\r' || str[len - 1] == '\n'))
    {
        str[len - 1] = '\0';
        len--;
    }
}
