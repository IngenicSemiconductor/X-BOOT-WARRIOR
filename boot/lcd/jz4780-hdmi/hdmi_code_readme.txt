hdmi����˵��
=============

Ŀ¼�ṹ
---------
jzhdmi
������ api: ����HDMI�ļĴ����ܶ࣬��api�з�װ�˽ӿڷ����ϲ���ã�Ŀǰ��Ҫ����hdmi_demo_tx����
������ bsp: �������ǵ������������ϵͳ�޹صģ�ʹ�ô�C��д,��bspĿ¼�·����˺�ƽ̨��صģ���Ҫ�мĴ������ʽӿڣ��ж�enable/disable�ӿ�
������ core: ���Ĵ��룬�󲿷ּĴ������ö��ڴ�Ŀ¼�£�ÿ��ģ���Ӧһ��halxxx.c�����Ŀ¼�»���audio.c, video.c, packets.c controls.c���⼸���ļ���halxxx.c�Ļ����Ͻ����˽�һ���ķ�װ��ʵ����api.h�еĲ��ֽӿ�
������ docs: ��HDMI��ص��ĵ�����׼��
������ edid: edid�Ķ�ȡ��������halxxx.c�Ƿ�װ�˼Ĵ����ķ��ʣ�dtd.c�Ƕ�CEA-861-D�и���format���������ķ�װ������Ҫ�ķ�����dtd_Fill, edid.c��Ҫ�����ǽ���EDID, hdmivsdb.c����shortAudioDesc.c, shortVideo.c��װ����ؽṹ��edid�����Ľ��������Щ�ṹ
������ hdcp: �ͼ�����صģ�Ŀǰ���ǻ�û�õ�
������ hdmi_demo_tx: һ��demo����������
������ phy: ��phy��صĲ�������ʼ��phy, дphy�ļĴ���
������ util: ��log����ص�һЩС����
----main.c: ��linux�Ľӿ�,module_init, module_exit�������ioctl��صĴ�����û�õģ�����ȥ��

git��֧˵��
------------
control_ok_orig: ���ڵ�һ��controller����ʱ�İ汾��������������phy��ص�
controller_may_ok: Ҳ�ǻ��ڵ�һ��controller����ʱ�İ汾

��Ҫ��˵��
-----------
* core/video.c��video_ForceOutput�����У�ȥ��force = 1��ע�ͣ�����ǿ�����ĳ����ɫ���������������ɫ������halFrameComposerDebug_ForceVideo�У�Ŀǰ�Ǻ�ɫ
	1. video force: ����video_ForceOutput(TRUE), �����ǵ���halFrameComposerDebug_ForceVideo������õģ�ֻ�������ɫ
	2. audio force: 8��ͨ���ɷֱ����ã������᲻�������*o*), ÿ��ͨ����������24bit������
			Ҫʹ��audio force��Ҫ�޸�video_ForceOutput��ʵ�֣�����halFrameComposerDebug_ForceAudio�ĵ��õڶ���������force
			����Ҫ�޸�halFrameComposerDebug_ForceAudio��ʵ�֣�Ŀǰû�и��������������ݣ�ȫ�����Ǿ�����
			
	VideoSampler: sampler�Ĳ���������Ҫע�⣬hsync, vsync, de��polarity, LCD�͹�������RGB��ʽ
* edid/dtd.c�е�dtd_Fill��Ŀǰ�����õ���format 3���޸�dtd->mHSyncPolarity = dtd->mVSyncPolarity��������hsync, vsync�ļ���
* Data Enable�ļ����ǵ���api_Initializeʱ�������õģ�������Ҫ�ı�Data Enable����Ҫ�޸�api_Initialize�����޸ĵ������ĵط�
* HDMI�������������Ѳ���Data Enable��������core/video.c��video_VideoSampler�����е��õ�halVideoSampler_InternalDataEnableGenerator�����һ���������ã�1����HDMI�ڲ�generator��0ʹ������LCD�����������DE��
* ���к�phyС����صĶ���phy/phy.c��

hdmi_demo˵��
-------------
auto���̷���
============
mainFunction
	access_Initialize: ��ʼ���˻���ַ�Լ����ڼĴ���������ʵ�mutex
	system_ThreadCreate: ����һ���̣߳��ȴ��û����벢���з���(tokenize)������buffer���飬�߳�ִ������cliFunction
	���ѡ�����auto������compliance_start()
		ע��hotplug��handler
		api_Initialize()
		compliance_Init()
		Ȼ��ͽ���һ����ѭ����
			��һ����ѭ�����ȴ��������EDID��ȡ���
			compiance_Configure
				Ŀǰ����ǿ��ʹ��ecaCode 3����720x480p
			Ȼ���ֽ�����һ����ѭ�����γ�����EDID��д���������ʹ���ѭ���˳�
				��һ��ִ��ѭ��ʱ���ӡ��Ƶ��ʽ��Ϣ��ƽʱ����������Ĵ�����Ҳ���Լ�����
			compiance_Standby
			compiance_Init
			��������Կ�����compilance������������ɣ�Init, Configure, Standby
		���������ص��ö�����ʲô��Ҫע�⣬����ʵ�ֶ����ں�̬���û�ֻ̬��ͨ��ioctl����
		api_Initialize
			��μ�Դ��������ӵ�����ע��
		compliance_Init(): ׼������params
			׼��product params(product params��ʲô����?)
			׼��audio params(audio params��ʲô����?)
			׼��video params(video params��ʲô����?): Ŀǰ���õ�������RGB, ���RGB
		compliance_Configure():
			����������sink���ص�video descriptor������api_Configure���üĴ�����������óɹ���compiance_Configure
				�Ӵ���������Audio���Թص�(audioOn), HDCPҲ���Թص�(hcdpOn)
				api_Configure
					video_Configure
					audio_Configure
					control_Configure
					phy_Configure
					����video_ForceOutput --->ForceOutput���������
				api_Configure�����ԭ��
					HPDΪfalse,������û�в���
