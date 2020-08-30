<?php
namespace App\Controller;

use Symfony\Bundle\FrameworkBundle\Controller\AbstractController;
use Symfony\Component\HttpFoundation\JsonResponse;
use Symfony\Component\HttpFoundation\Request;
use Symfony\Component\Routing\Annotation\Route;
use App\Entity\Server;
use App\Repository\ServerRepository;
use Doctrine\ORM\EntityManagerInterface;

class ServerController extends AbstractController {

     /**
      * @param Request $request
      * @return JsonResponse
      * @throws \Exception
      * @Route("/servers", name="servers_add", methods={"POST"})
     */
    public function postServer(Request $request) {
        try{
            $request = $this->transformJsonBody($request);
            
            if (!$request || !$request->get('name')){
                $data = [
                    'status' => 422,
                    'errors' => $request
                ];
                return $this->response($data);
                throw new \Exception();
            }

            $server = new Server();
            $server->setName($request->get('name'));
            $server->setPlayercount(1);
            $server->setCreated(new \DateTime("now"));
            $server->setLastPing(new \DateTime("now"));
            $server->setIp($request->get("lobby"));
            $server->setMap($request->get('map'));


        $entityManager = $this->getDoctrine()->getManager();
        $entityManager->persist($server);
        $entityManager->flush();

        $data = [
            'status' => 200,
            'success' => $server->getId()
        ];
        return $this->response($data);
        
        }catch (\Exception $e){
            $data = [
                'status' => 422,
                'errors' => "Invalid Data"
            ];
            return $this->response($data, 422);
        }
    }
    /**
     * @param $id
     * @param EntityManagerInterface $entityManager
     * @param ServerRepository $serverRepository
     * @return JsonResponse
     * @Route("/ping/{id}", name="ping_server", methods={"GET"})
   */
    public function ping($id, EntityManagerInterface $entityManager, ServerRepository $serverRepository
    ) {
         try{
             $server = $serverRepository->find($id);

             if (!$server){
                 $data = [
                     'status' => 404,
                     'errors' => "Post not found",
                 ];
                 return $this->response($data, 404);
             }
             $server->setLastping(new \DateTime("now"));
             $entityManager->persist($server);
             $entityManager->flush();

             $data = [
                 'status' => 200,
                 'success' => $server->getId()
             ];
        return $this->response($data);

         }catch (\Exception $e){
             $data = [
                 'status' => 422,
                 'errors' => "Data no valid",
             ];
             return $this->response($data, 422);
         }
        
    }

        /**
     * @param $id
     * @param EntityManagerInterface $entityManager
     * @param ServerRepository $serverRepository
     * @return JsonResponse
     * @Route("/playerjoin/{id}", name="playerjoined_server", methods={"GET"})
   */
    public function joinServer($id, EntityManagerInterface $entityManager, ServerRepository $serverRepository
    ) {
         try{
             $server = $serverRepository->find($id);

             if (!$server){
                 $data = [
                     'status' => 404,
                     'errors' => "Post not found",
                 ];
                 return $this->response($data, 404);
             }
             $server->setPlayercount($server->getPlayercount() + 1);
             $entityManager->persist($server);
             $entityManager->flush();

             $data = [
                 'status' => 200,
                 'success' => $server->getId()
             ];
        return $this->response($data);

         }catch (\Exception $e){
             $data = [
                 'status' => 422,
                 'errors' => "Data no valid",
             ];
             return $this->response($data, 422);
         }
        
    }

        /**
     * @param $id
     * @param EntityManagerInterface $entityManager
     * @param ServerRepository $serverRepository
     * @return JsonResponse
     * @Route("/playerleave/{id}", name="playerleave_server", methods={"GET"})
   */
    public function leaveServer($id, EntityManagerInterface $entityManager, ServerRepository $serverRepository
    ) {
         try{
             $server = $serverRepository->find($id);

             if (!$server){
                 $data = [
                     'status' => 404,
                     'errors' => "Post not found",
                 ];
                 return $this->response($data, 404);
             }
             $server->setPlayercount($server->getPlayercount() - 1);
             $entityManager->persist($server);
             $entityManager->flush();

             $data = [
                 'status' => 200,
                 'success' => $server->getId()
             ];
        return $this->response($data);

         }catch (\Exception $e){
             $data = [
                 'status' => 422,
                 'errors' => "Data no valid",
             ];
             return $this->response($data, 422);
         }
        
    }

    /**
     * @param $id
     * @param ServerRepository $serverRepository
     * @return JsonResponse
     * @Route("/requestip/{id}", name="request_server", methods={"GET"})
   */
    public function requestServer($id, ServerRepository $serverRepository ) {
         try{
             $server = $serverRepository->find($id);

             if (!$server){
                 $data = [
                     'status' => 404,
                     'errors' => "Post not found",
                 ];
                 return $this->response($data, 404);
             }
             $data = [
                 'status' => 200,
                 'success' => $server->getIp()
             ];
        return $this->response($data);

         }catch (\Exception $e){
             $data = [
                 'status' => 422,
                 'errors' => "Data no valid",
             ];
             return $this->response($data, 422);
         }
        
    }
    
    /**
      * @return JsonResponse
      * @throws \Exception
      * @Route("/servers", name="servers_get", methods={"GET"})
     */
    public function getServers() {
        
        $date = new \DateTime();
        $date->modify('-10 second');
        $repository = $this->getDoctrine()->getRepository(Server::class);
        
        $servers =$repository->createQueryBuilder('s')
                             ->andWhere('s.lastping > :date')
                             ->setParameter(':date', $date)
                             ->getQuery()
                             ->execute();
        
        $data = [
            'status' => 200,
            'success' => $servers,
        ];
        return $this->response($data);
   }

    /**
      * @return JsonResponse
      * @throws \Exception
      * @Route("/allservers", name="allservers_get", methods={"GET"})
     */
    public function getAllServers() {
        
        $repository = $this->getDoctrine()->getRepository(Server::class);
        
        $servers =$repository->findAll();
        
        $data = [
            'status' => 200,
            'success' => $servers,
        ];
        return $this->response($data);
   }
    
      /**
       * Returns a JSON response
       *
       * @param array $data
       * @param $status
       * @param arrany $headers
       * @return JsonResponse
       */
    public function response($data, $status = 200, $headers = [])
    {
        return new JsonResponse($data, $status, $headers);
    }

    protected function transformJsonBody(\Symfony\Component\HttpFoundation\Request $request)
    {
        $data = json_decode($request->getContent(), true);
        
        if ($data === null) {
            return $request;
        }

        $request->request->replace($data);
        
        return $request;
    }
}
?>
